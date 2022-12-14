defmodule Tauper.Games do
  @moduledoc """
  The Games context.
  """

  import Ecto.Query, warn: false
  alias Tauper.Repo

  alias Tauper.Games.{Supervisor, Game, Server}

  @registry :game_registry

  @doc """
  Creates a new game with the code game.

  It returns an error it the game exists.

  ## Examples
      iex> new_game("123")
      [%Game{}, ...]
  """
  def new_game(game_code) do
    Supervisor.start_child(game_code)
  end

  def start_game(game_code) do
    Server.start(game_code)
  end

  def game(game_code) do
    Server.game(game_code)
  end

  def lookup(game_code) do
    Registry.lookup(@registry, game_code)
  end

  def next_question(game_code) do
    Server.next(game_code)
  end

  def answer(game_code, answer, player) do
    Server.answer(game_code, answer, player)
  end

  def podium(game_code) do
    Server.podium(game_code)
  end

  def list_game_codes() do
    Registry.select(@registry, [{{:"$1", :_, :_}, [], [:"$1"]}])
  end

  @doc """
  Returns the list of games.

  ## Examples

      iex> list_games()
      [%Game{}, ...]

  """
  def list_games do
    Repo.all(Game)
  end

  @doc """
  Gets a single game.

  Raises `Ecto.NoResultsError` if the Game does not exist.

  ## Examples

      iex> get_game!(123)
      %Game{}

      iex> get_game!(456)
      ** (Ecto.NoResultsError)

  """
  def get_game!(id), do: Repo.get!(Game, id)

  def get_game(id), do: Repo.get(Game, id)

  def get_game_by_code(code), do: Repo.get_by(Game, code: code)

  @doc """
  Creates a game.

  ## Examples

      iex> create_game(%{field: value})
      {:ok, %Game{}}

      iex> create_game(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_game(attrs \\ %{}) do
    %Game{}
    |> Game.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a game.

  ## Examples

      iex> update_game(game, %{field: new_value})
      {:ok, %Game{}}

      iex> update_game(game, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_game(%Game{} = game, attrs) do
    game
    |> Game.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a game.

  ## Examples

      iex> delete_game(game)
      {:ok, %Game{}}

      iex> delete_game(game)
      {:error, %Ecto.Changeset{}}

  """
  def delete_game(%Game{} = game) do
    Repo.delete(game)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking game changes.

  ## Examples

      iex> change_game(game)
      %Ecto.Changeset{data: %Game{}}

  """
  def change_game(%Game{} = game, attrs \\ %{}) do
    Game.changeset(game, attrs)
  end

  def generate_code do
    :rand.uniform(999) |> Integer.to_string() |> String.pad_leading(3, "0")
  end
end
