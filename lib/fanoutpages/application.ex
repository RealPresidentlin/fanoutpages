defmodule Fanoutpages.Application do
  # See https://elixir.hexdocs.pm/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      FanoutpagesWeb.Telemetry,
      Fanoutpages.Repo,
      {DNSCluster, query: Application.get_env(:fanoutpages, :dns_cluster_query) || :ignore},
      {Oban, Application.fetch_env!(:fanoutpages, Oban)},
      {Phoenix.PubSub, name: Fanoutpages.PubSub},
      # Start a worker by calling: Fanoutpages.Worker.start_link(arg)
      # {Fanoutpages.Worker, arg},
      # Start to serve requests, typically the last entry
      FanoutpagesWeb.Endpoint
    ]

    # See https://elixir.hexdocs.pm/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Fanoutpages.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    FanoutpagesWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
