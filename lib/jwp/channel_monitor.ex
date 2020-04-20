defmodule Jwp.ChannelMonitor do
  use GenServer, restart: :transient
  @supervisor Jwp.ChannelMonitor.Supervisor


  def watch(params) do
    DynamicSupervisor.start_child(@supervisor, {__MODULE__, params})
  end


  def start_link(params) do
    GenServer.start_link(__MODULE__, params)
  end

  def init(params) do
    monitor_ref = Process.monitor(params.channel_pid)
    state = Map.put(params, :monitor_ref, monitor_ref)
    send(self(), :after_init)
    {:ok, state}
  end


  def handle_info(:after_init, state) do
    if state.notify_joins, do: notify_webhooks_endpoint(state, "join")
    {:noreply, state, :hibernate}
  end


  def handle_info({:DOWN, ref, _, _, {:shutdown, _}}, %{monitor_ref: ref} = state) do
    if state.notify_leaves, do: notify_webhooks_endpoint(state, "leave")
    {:stop, :normal, state}
  end


  def handle_info({:DOWN, ref, _, _, _other_reason}, %{monitor_ref: ref} = state) do
    {:stop, :normal, state}
  end


  defp notify_webhooks_endpoint(state, event) do
    app = Jwp.Repo.get(Jwp.Apps.App, state.app_id)
    payload = Jason.encode!(%{channel: state.topic, event: event, socket_id: state.socket_id})
    headers = [{"authorization", app.webhooks_key}, {"content-type", "application/json"}]
    Mojito.post(app.webhooks_endpoint, headers, payload)
  end
end
