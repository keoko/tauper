defmodule PassaParaulaWeb.PageController do
  use PassaParaulaWeb, :controller
  import Phoenix.LiveView.Controller
  alias PassaParaula.Games
  alias PassaParaula.Games.Game

  def index(conn, _params) do
    changeset = Games.change_game(%Game{})
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
