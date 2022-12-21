defmodule TauperWeb.GameController do
  use TauperWeb, :controller
  import Phoenix.Controller

  alias Tauper.Games
  alias Tauper.Games.Game
  alias Ecto.Changeset

  def index(conn, _params) do
    games = Games.list_game_codes()
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
         [_pid] <- Games.lookup(code) do
      conn
      |> renew_session()
      |> put_session(:player_name, valid_params.player_name)
      |> put_session(:code, valid_params.game_code)
      |> redirect(to: Routes.game_play_path(conn, :play, valid_params.game_code))
    else
      [] ->
        conn
        |> put_flash(:error, "Invalid game code  '#{code}'. Please try another code.")
        |> render("new_join.html", changeset: change_join_game_request(params))

      {:error, %Changeset{} = changeset} ->
        render(conn, "new_join.html", changeset: changeset)
    end
  end

  def change_new_game_request(attrs \\ %{}) do
    types = %{
      num_questions: :integer,
      question_max_time: :integer,
      question_types: {:array, :string},
      element_groups: {:array, :integer}
    }

    # apply_action(:insert) needed to display error messages in the form
    # TODO how to convert question_types from sting to an atom (enums)?
    {%{}, types}
    |> Changeset.cast(attrs, Map.keys(types))
    |> Changeset.validate_required([
      :num_questions,
      :question_max_time,
      :question_types,
      :element_groups
    ])
    |> Changeset.validate_number(:num_questions, greater_than: 0)
    |> Changeset.validate_number(:question_max_time, greater_than: 0)
  end

  defp validate_new_params(params) do
    params
    |> change_new_game_request
    # apply_action(:insert) to force showing error messages in schemaless ecto validation
    |> Changeset.apply_action(:insert)
  end

  def create(conn, %{"new_game_form" => params}) do
    with code = Games.generate_code(),
         player_name = "owner",
         {:ok, game_params} <- validate_new_params(params),
         Games.new_game(code, game_params) do
      conn
      |> renew_session()
      |> put_session(:player_name, player_name)
      |> put_session(:code, code)
      |> redirect(to: Routes.game_show_path(conn, :show, code))
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
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
