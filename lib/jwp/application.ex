defmodule Jwp.Application do
  use Application

  def start(_type, _args) do
    children = [
      {Task.Supervisor, name: Jwp.TaskSup},
      {DynamicSupervisor, strategy: :one_for_one, name: Jwp.ChannelMonitor.Supervisor},
      {Phoenix.PubSub, name: Jwp.PubSub},
      JwpWeb.MainPresence,
      Jwp.Repo,
      JwpWeb.Endpoint
    ]

    opts = [strategy: :rest_for_one, name: Jwp.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def config_change(changed, _new, removed) do
    JwpWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
