defmodule Jwp.ChannelMonitor do
  use GenServer, restart: :transient
  @supervisor Jwp.ChannelMonitor.Supervisor


  def watch(socket, options) do
    DynamicSupervisor.start_child(@supervisor, {__MODULE__, [
      socket.channel_pid,
      socket.assigns.app_id,
      socket.assigns.socket_id,
      socket.assigns.short_topic,
      options
    ]})
  end


  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end


  def init([channel_pid, app_id, socket_id, topic, options]) do
    state = %{
      monitor_ref: Process.monitor(channel_pid),
      app_id: app_id,
      socket_id: socket_id,
      topic: topic,
      notify_leaves: options.notify_leaves
    }

    if options.notify_joins, do: notify_webhooks_endpoint(app_id, socket_id, topic, "join")

    {:ok, state, :hibernate}
  end


  def handle_info({:DOWN, ref, _, _, {:shutdown, _}}, %{monitor_ref: monitor_ref} = state) when monitor_ref == ref do
    if state.notify_leaves, do: notify_webhooks_endpoint(state.app_id, state.socket_id, state.topic, "leave")
    {:stop, :normal, state}
  end


  defp notify_webhooks_endpoint(app_id, socket_id, topic, event) do
    Task.Supervisor.start_child(Jwp.TaskSup, fn ->
      app = Jwp.Repo.get(Jwp.Apps.App, app_id)
      payload = Jason.encode!(%{channel: topic, event: event, socket_id: socket_id})
      Mojito.post(app.webhooks_endpoint, [{"authorization", app.webhooks_key}, {"content-type", "application/json"}], payload)
    end)
  end
end
