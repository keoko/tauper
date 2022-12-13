defmodule TauperWeb.GameController do
  use TauperWeb, :controller
  import Phoenix.Controller

  alias Tauper.Games
  alias Tauper.Games.Game
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

  defp validate_join_params(params) do
    params
    |> change_join_game_request
    # apply_action(:insert) to force showing error messages in schemaless ecto validation
    |> Changeset.apply_action(:insert)
  end

  def join(conn, %{"join_game_params" => %{"game_code" => code} = params}) do
    with {:ok, valid_params} <- validate_join_params(params),
         %Tauper.Games.Game{} = game <- Games.get_game_by_code(code) do
      conn
      |> renew_session()
      |> put_session(:current_player_name, valid_params.player_name)
      |> put_session(:current_game_code, valid_params.game_code)
      |> redirect(to: Routes.game_path(conn, :play, game.id))
    else
      nil ->
        conn
        |> put_flash(:error, "Invalid game code  '#{code}'. Please try another code.")
        |> render("new_join.html", changeset: change_join_game_request(params))

      {:error, %Changeset{} = changeset} ->
        render(conn, "new_join.html", changeset: changeset)
    end
  end

  # def join(conn, %{"join_game_params" => %{"game_code" => code} = params}) do
  #   changeset =
  #     params
  #     |> change_join_game_request
  #     # apply_action(:insert) to force showing error messages in schemaless ecto validation
  #     |> Changeset.apply_action(:insert)

  #   case changeset do
  #     {:error, %Changeset{} = changeset} ->
  #       render(conn, "new_join.html", changeset: changeset)

  #     {:ok, fields} ->
  #       game = Games.get_game_by_code(code)

  #       case game do
  #         %Tauper.Games.Game{} ->
  #           conn
  #           |> renew_session()
  #           |> put_session(:current_player_name, fields.player_name)
  #           |> put_session(:current_game_code, fields.game_code)
  #           |> redirect(to: Routes.game_path(conn, :play, game.id))

  #         # |> redirect(to: Routes.game_path(conn, :show, game))

  #         nil ->
  #           {_, changeset} = changeset

  #           conn
  #           |> put_flash(:error, "Invalid game code. Please try another code.")
  #           |> render("new_join.html", changeset: changeset)
  #       end
  #   end
  # end

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
    render(conn, "show.html", game: game)
    # live_render(conn, TauperWeb.CounterLive,
    #   session: %{
    #     "game_code" => game.code
    #   }
    # )
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

  # This function renews the session ID and erases the whole
  # session to avoid fixation attacks. If there is any data
  # in the session you may want to preserve after log in/log out,
  # you must explicitly fetch the session data before clearing
  # and then immediately set it after clearing, for example:
  #
  #     defp renew_session(conn) do
  #       preferred_locale = get_session(conn, :preferred_locale)
  #
  #       conn
  #       |> configure_session(renew: true)
  #       |> clear_session()
  #       |> put_session(:preferred_locale, preferred_locale)
  #     end
  #
  defp renew_session(conn) do
    conn
    |> configure_session(renew: true)
    |> clear_session()
  end
end
