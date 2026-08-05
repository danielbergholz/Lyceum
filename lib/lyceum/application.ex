defmodule Lyceum.Application do
  # See https://elixir.hexdocs.pm/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      LyceumWeb.Telemetry,
      Lyceum.Repo,
      {DNSCluster, query: Application.get_env(:lyceum, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Lyceum.PubSub},
      # Start a worker by calling: Lyceum.Worker.start_link(arg)
      # {Lyceum.Worker, arg},
      # Start to serve requests, typically the last entry
      LyceumWeb.Endpoint
    ]

    # See https://elixir.hexdocs.pm/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Lyceum.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    LyceumWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
