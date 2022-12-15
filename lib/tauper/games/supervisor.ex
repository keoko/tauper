defmodule Tauper.Games.Supervisor do
  use DynamicSupervisor
  alias Tauper.Games.Server

  def start_link(_args) do
    DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def start_child(game_code, game_params) do
    child_spec = {Server, code: game_code, params: game_params}

    DynamicSupervisor.start_child(__MODULE__, child_spec)
  end

  @impl true
  def init(_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
