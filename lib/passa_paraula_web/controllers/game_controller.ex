defmodule PassaParaulaWeb.GameController do
  use PassaParaulaWeb, :controller
  import Phoenix.LiveView.Controller

  alias PassaParaula.Games
  alias PassaParaula.Games.Game
  alias Ecto.Changeset

  def index(conn, _params) do
    games = Games.list_games()
    render(conn, "index.html", games: games)
  end

  def new(conn, _params) do
    changeset = Games.change_game(%Game{})
    render(conn, "new.html", changeset: changeset)
  end

  def change_join_game_request(attrs \\ %{}) do
    types = %{
      game_code: :string,
      player_name: :string
    }

    # apply_action(:insert) needed to display error messages in the form
    {%{}, types}
    |> Changeset.cast(attrs, Map.keys(types))
    |> Changeset.validate_required([:game_code, :player_name])
    |> Changeset.validate_length(:game_code, min: 3, max: 3)
    |> Changeset.validate_length(:player_name, min: 1, max: 10)
  end

  def new_join(conn, params) do
    changeset = change_join_game_request(params)
    render(conn, "new_join.html", changeset: changeset)
  end

  def join(conn, %{"join_game_params" => %{"game_code" => code} = params}) do
    changeset =
      params
      |> change_join_game_request
      # apply_action(:insert) to force showing error messages in schemaless ecto validation
      |> Changeset.apply_action(:insert)

    case changeset do
      {:error, %Changeset{} = changeset} ->
        render(conn, "new_join.html", changeset: changeset)

      {:ok, _fields} ->
        game = Games.get_game_by_code(code)
        dbg()

        case game do
          %PassaParaula.Games.Game{} ->
            conn
            |> redirect(to: Routes.game_path(conn, :show, game))

          nil ->
            conn
            |> put_flash(:error, "Invalid game code. Please try another code.")
            |> render(conn, "new_join.html", changeset: changeset)
        end
    end
  end

  # def create(conn, %{"game" => game_params}) do
  #   case Games.create_game(game_params) do
  #     {:ok, game} ->
  #       conn
  #       |> put_flash(:info, "Game created successfully.")
  #       |> redirect(to: Routes.game_path(conn, :show, game))

  #     {:error, %Ecto.Changeset{} = changeset} ->
  #       render(conn, "new.html", changeset: changeset)
  #   end
  # end

  def create(conn, _params) do
    # TODO generate code
    # TODO pass params code and status "not_started"
    game_params = %{code: Games.generate_code(), status: "not_started"}

    case Games.create_game(game_params) do
      {:ok, game} ->
        conn
        |> put_flash(:info, "Game created successfully with code " <> game_params.code)
        |> redirect(to: Routes.game_path(conn, :show, game))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    game = Games.get_game!(id)
    # render(conn, "show.html", game: game)
    live_render(conn, PassaParaulaWeb.CounterLive,
      session: %{
        "game_code" => game.code
      }
    )
  end

  def edit(conn, %{"id" => id}) do
    game = Games.get_game!(id)
    changeset = Games.change_game(game)
    render(conn, "edit.html", game: game, changeset: changeset)
  end

  def update(conn, %{"id" => id, "game" => game_params}) do
    game = Games.get_game!(id)

    case Games.update_game(game, game_params) do
      {:ok, game} ->
        conn
        |> put_flash(:info, "Game updated successfully.")
        |> redirect(to: Routes.game_path(conn, :show, game))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", game: game, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    game = Games.get_game!(id)
    {:ok, _game} = Games.delete_game(game)

    conn
    |> put_flash(:info, "Game deleted successfully.")
    |> redirect(to: Routes.game_path(conn, :index))
  end
end
