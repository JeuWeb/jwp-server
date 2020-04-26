defmodule Jwp.PubSub.ChannelMonitor do
  use GenServer, restart: :transient
  require Logger
  
  @supervisor Jwp.PubSub.ChannelMonitor.Supervisor
  @state_keys [:notify_joins, :notify_leaves, :app_id, :topic, :socket_id, :channel_pid]
  

  def watch(params) do
    case validate_params(params) do
      {:ok, params} -> DynamicSupervisor.start_child(@supervisor, {__MODULE__, params})
      err -> err
    end
  end


  defp validate_params(params) do
    Enum.reject(@state_keys, &Map.has_key?(params, &1))
    |> case do
        [] -> {:ok, Map.take(params, @state_keys)}
        missing -> {:error, {:missing_keys, missing}}
      end
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


  def handle_info({:DOWN, ref, _, _, {:shutdown, _} = reason}, %{monitor_ref: ref} = state) do
    Logger.debug("Channel :DOWN #{inspect reason}")
    if state.notify_leaves, do: notify_webhooks_endpoint(state, "leave")
    {:stop, :normal, state}
  end


  def handle_info({:DOWN, ref, _, _, reason}, %{monitor_ref: ref} = state) do
    Logger.debug("Channel :DOWN #{inspect reason}")
    {:stop, :normal, state}
  end


  defp notify_webhooks_endpoint(state, event) do
    app = Jwp.Repo.get(Jwp.Apps.App, state.app_id)
    case app.webhooks_endpoint do
      nil -> 
        Logger.debug("No endpoint configured for app #{state.app_id}")
        :ok
      endpoint ->
        payload = Jason.encode!(%{channel: state.topic, event: event, socket_id: state.socket_id})
        headers = [{"authorization", app.webhooks_key}, {"content-type", "application/json"}]
        Logger.debug("Calling webhook endpoint #{endpoint} for event '#{event}'")
        HTTPoison.post(endpoint, payload, headers)
        |> case do
          {:ok, _} -> :ok
          {:error, reason} -> Logger.error(inspect reason)
        end
    end
  end
end
