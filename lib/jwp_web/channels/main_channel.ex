defmodule JwpWeb.MainChannel do
  use JwpWeb, :channel
  alias JwpWeb.MainPresence, as: Presence
  require Logger
  import Jwp.ChannelConfig, only: [cc: 0, cc: 1, cc: 2]
  alias Pow.Ecto.Schema.Password.Pbkdf2

  def join("jwp:" <> scope = channel, %{"auth" => token} = params, socket) do
    with {:ok, claim_app_id, short_topic} <- decode_scope(scope),
         json_data when is_binary(json_data) <- Map.get(params, "data", ""),
         :ok <- verify_auth(claim_app_id, socket.assigns.socket_id, short_topic, json_data, token),
         {:ok, config} <- parse_json_config(json_data) do
            Logger.debug("joining '#{short_topic}'")
            send(self(), :after_join)
            maybe_poll_history(channel, params)
            socket = socket
            |> assign(:app_id, claim_app_id)
            |> assign(:short_topic, short_topic)
            |> assign(:config, config)
            {:ok, %{}, socket}
    else
      err ->
        Logger.error(inspect(err))
        {:error, %{reason: "unauthorized"}}
    end
  end

  def join(_,params,_) do
    {:error, %{reason: "unauthorized", params: params}}
  end

  defp decode_scope(scope) do
    with [claim_app_id, short_topic] <- String.split(scope, ":", parts: 2) do
      {:ok, claim_app_id, short_topic}
    else
      err -> {:error, {:bad_scope, err}}
    end
  end

  defp verify_auth(claim_app_id, socket_id, short_topic, json_data, signature) do
    case Jwp.Repo.fetch(Jwp.Apps.App, claim_app_id) do
      :error -> {:error, {:app_not_found, claim_app_id}}
      # If ok we will digest the auth string and compare the results
      {:ok, %{secret: secret}} ->
          auth_string = case json_data do
            "" -> "#{socket_id}:#{short_topic}"
            json -> "#{socket_id}:#{short_topic}:#{json}"
          end
          expected = digest(secret, auth_string)
          case compare_hash(expected, signature) do
            true -> :ok
            #@todo do not log good signatures
            false -> {:error, {:bad_signature, signature, expected}}
          end
    end
  end

  defp digest(secret, data),
    do: :crypto.hmac(:sha256, secret, data) |> Base.encode16

  defp compare_hash(a, b),
    do: Pbkdf2.compare(a, b)

  defp parse_json_config(json) do
    case Jason.decode(json) do
      {:ok, data} -> import_config(data)
      other -> other
    end
  end

  defp import_config(data) do
    data
    |> Map.get("options", %{})
    |> Map.put("meta", Map.get(data, "meta", nil))
    |> Jwp.ChannelConfig.from_map
  end

  def handle_info(:after_join, socket) do
    cc(presence_track: pt, presence_diffs: pd, meta: meta, notify_joins: notify_joins, notify_leaves: notify_leaves) =
      get_config(socket)

    if(pd, do: init_presence_state(socket))
    if(pt, do: track_presence(socket, meta))
    {:ok, _} = Jwp.ChannelMonitor.watch(%{
      app_id: socket.assigns.app_id,
      socket_id: socket.assigns.socket_id,
      channel_pid: socket.channel_pid,
      topic: socket.assigns.short_topic,
      notify_joins: notify_joins,
      notify_leaves: notify_leaves
    })

    {:noreply, socket}
  end

  def handle_info({:history_message, event, payload}, socket) do
    push(socket, event, payload)
    {:noreply, socket}
  end

  def handle_info(msg, socket) do
    Logger.warn("Unhandled info in #{__MODULE__}: #{inspect(msg)}")
    {:noreply, socket}
  end

  def handle_in(msg, socket) do
    Logger.warn("Unhandled IN in #{__MODULE__}: #{inspect(msg)}")
    {:noreply, socket}    
  end

  defp init_presence_state(socket) do
    list = Presence.list(socket)
    IO.inspect(list, label: "PRESENCE LIST")
    push(socket, "presence_state", list)
  end

  defp track_presence(socket, meta) do
    case get_id(socket) do
      nil -> push_error(socket, "socket_id missing, presence tracking is disabled")
      id -> {:ok, _} = Presence.track(socket, id, meta)
    end
  end

  # when is_map(tid)
  defp maybe_poll_history(channel, %{"last_message_id" => nil}),
    do: :ok

  defp maybe_poll_history(channel, %{"last_message_id" => tid}) do
    this = self()

    # @todo link task to channel process ?
    Task.Supervisor.start_child(Jwp.TaskSup, fn ->
      messages =
        Jwp.History.get_messages_after(channel, tid)
        |> Enum.each(fn {event, payload} ->
          send(this, {:history_message, event, payload})
        end)
    end)
  end

  defp maybe_poll_history(_, _),
    do: :ignore

  defp get_config(socket),
    do: socket.assigns.config

  defp get_name(socket),
    do: socket.assigns.short_topic

  defp get_id(socket),
    do: socket.assigns.socket_id

  defp push_error(socket, message) do
    push(socket, "jwp_system", %{
      type: "error",
      message: "socket_id missing, presence tracking is disabled"
    })
  end

end
