defmodule JwpWeb.MainChannel do
  use JwpWeb, :channel
  alias JwpWeb.MainPresence, as: Presence
  require Logger
  import Jwp.ChannelConfig, only: [cc: 0, cc: 1, cc: 2]

  def join("jwp:" <> scope = channel, payload, socket) do
    with {:ok, claim_id, short_topic} <- decode_scope(scope),
         :ok <- check_app_id(socket, claim_id),
         {:ok, conf} <- check_channel(socket, short_topic) do
      Logger.debug("joining '#{short_topic}'")
      Logger.debug(Jwp.ChannelConfig.format(conf))
      # history will send messages to this channel process from a Task
      send(self(), :after_join)
      maybe_poll_history(channel, payload)
      {:ok, assign(socket, :short_topic, short_topic)}
    else
      err ->
        Logger.error(inspect(err))
        {:error, %{reason: "unauthorized"}}
    end
  end


  defp decode_scope(scope) do
    with [claim_id, name] <- String.split(scope, ":") do
      {:ok, claim_id, name}
    else
      err -> {:error, {:bad_scope, err}}
    end
  end

  defp check_app_id(socket, app_id) do
    case socket.assigns.app_id do
      ^app_id -> :ok
      _ -> {:error, {:cannot_claim, app_id}}
    end
  end

  defp check_channel(socket, channel) do
    case Map.fetch(socket.assigns.allowed_channels, channel) do
      {:ok, cc() = conf} -> {:ok, conf}
      :error -> {:error, {:not_allowed, channel}}
    end
  end

  def handle_info(:after_join, socket) do
    cc(presence_track: pt, presence_diffs: pd, meta: meta, notify_joins: notify_joins, notify_leaves: notify_leaves) =
      chan_conf!(socket)

    if(pd, do: init_presence_state(socket))
    if(pt, do: track_presence(socket, meta))
    Jwp.ChannelMonitor.watch(socket, %{notify_joins: notify_joins, notify_leaves: notify_leaves})

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

  defp chan_conf!(socket) do
    case socket.assigns.allowed_channels[get_name(socket)] do
      nil ->
        raise "Channel configuration for #{socket.get_name(socket)} not found in #{
                inspect(socket.assigns.allowed_channels)
              }"

      found ->
        found
    end
  end

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
