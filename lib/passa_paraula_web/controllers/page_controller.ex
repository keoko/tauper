defmodule PassaParaulaWeb.PageController do
  use PassaParaulaWeb, :controller
  import Phoenix.LiveView.Controller
  alias PassaParaula.Games
  alias PassaParaula.Games.Game
  alias Ecto.Changeset
  alias PassaParaulaWeb.GameController

  def index(conn, params) do
    changeset = GameController.change_join_game_request(params)
    render(conn, "index.html", changeset: changeset)
  end

  # def index(conn, params) do
  #   game_code = Map.get(params, "game_code", "001")
  #   IO.puts "params:#{inspect(params)}"
  #   live_render(conn, PassaParaulaWeb.CounterLive,
  #     session: %{
  #       "game_code" => game_code
  #     }
  #   )
  # end
end
