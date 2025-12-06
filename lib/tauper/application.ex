defmodule Tauper.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @registry :game_registry

  @impl true
  def start(_type, _args) do
    children = [
      # Start Game Registry
      {Registry, [keys: :unique, name: @registry]},
      # Start Game Supervisor
      {Tauper.Games.Supervisor, []},
      # Start the Telemetry supervisor
      TauperWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Tauper.PubSub},
      TauperWeb.Presence,
      # Start the Endpoint (http/https)
      TauperWeb.Endpoint
      # Start a worker by calling: Tauper.Worker.start_link(arg)
      # {Tauper.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Tauper.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    TauperWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
