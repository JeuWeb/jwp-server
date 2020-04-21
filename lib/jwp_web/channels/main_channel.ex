defmodule JwpWeb.MainChannel do
  use JwpWeb, :channel
  alias JwpWeb.MainPresence, as: Presence
  require Logger
  import Jwp.ChannelConfig, only: [cc: 0, cc: 1, cc: 2], warn: false

  # We give the assigned socket_id of the socket to the verification
  # function. The remote client has computed a signature with a
  # socket_id for this channel. If the signature is valid, it means
  # that the token was actually issued for this socket_id.
  def join("jwp:" <> scope = channel, %{"auth" => token} = params, socket) do
    with  {:ok, claim_app_id, short_topic} <- decode_scope(scope),
          :ok <- check_app_id(socket, claim_app_id),
          {:ok, json_data} <- get_json_config(params),
          :ok <- Jwp.Auth.SocketAuth.verify_channel_token(claim_app_id, socket.assigns.socket_id, short_topic, json_data, token),
          {:ok, config} <- parse_json_config(json_data) do
            send(self(), :after_join)
            maybe_poll_history(channel, params)
            socket = socket
              |> assign(:short_topic, short_topic)
              |> assign(:config, config)
            {:ok, %{}, socket}
    else
      err ->
        Logger.error(inspect(err))
        {:error, %{reason: "unauthorized"}}
    end
  end

  def join(_,_params,_) do
    {:error, %{reason: "unauthorized"}}
  end

  defp decode_scope(scope) do
    with {:ok, [claim_app_id, short_topic]} <- Jwp.Auth.SocketAuth.split(scope, 2) do
      {:ok, claim_app_id, short_topic}
    else
      err -> {:error, {:bad_scope, err}}
    end
  end

  defp check_app_id(socket, claim_app_id) do
    case socket.assigns.app_id do 
      ^claim_app_id -> :ok
      _ -> {:error, :bad_app_id}
    end
  end

  defp get_json_config(%{"data" => json}) when is_binary(json),
    do: {:ok, json}

  defp get_json_config(%{"data" => _}),
    do: {:error, :invalid_data}

  defp get_json_config(_no_data_param),
    do: {:ok, nil}

  defp parse_json_config(nil),
    do: import_config(%{})

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
    push(socket, "presence_state", list)
  end

  defp track_presence(socket, meta) do
    case get_id(socket) do
      nil -> push_error(socket, "socket_id missing, presence tracking is disabled")
      id -> {:ok, _} = Presence.track(socket, id, meta)
    end
  end

  # when is_map(tid)
  defp maybe_poll_history(_channel, %{"last_message_id" => nil}),
    do: :ok

  defp maybe_poll_history(channel, %{"last_message_id" => tid}) do
    this = self()

    # @todo link task to channel process ?
    Task.Supervisor.start_child(Jwp.TaskSup, fn ->
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

  defp get_id(socket),
    do: socket.assigns.socket_id

  defp push_error(socket, message) do
    push(socket, "jwp_system", %{
      type: "error",
      message: message
    })
  end

end
