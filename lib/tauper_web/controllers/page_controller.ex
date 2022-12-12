defmodule TauperWeb.PageController do
  use TauperWeb, :controller
  import Phoenix.LiveView.Controller
  alias Tauper.Games
  alias Tauper.Games.Game
  alias Ecto.Changeset
  alias TauperWeb.GameController

  def index(conn, params) do
    changeset = GameController.change_join_game_request(params)
    render(conn, "index.html", changeset: changeset)
  end

  # def index(conn, params) do
  #   game_code = Map.get(params, "game_code", "001")
  #   IO.puts "params:#{inspect(params)}"
  #   live_render(conn, TauperWeb.CounterLive,
  #     session: %{
  #       "game_code" => game_code
  #     }
  #   )
  # end
end
