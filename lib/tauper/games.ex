defmodule Tauper.Games do
  @moduledoc """
  The Games context.
  """

  import Ecto.Query, warn: false

  alias Tauper.Games.{Supervisor, Server}

  @registry :game_registry

  @doc """
  Creates a new game with the code game.

  It returns an error it the game exists.

  ## Examples
  iex> new_game("123", [num_questions: 20, question_types: ["symbol"]])
      [%Game{}, ...]
  """
  def new_game(game_code, game_params \\ %{}) do
    Supervisor.start_child(game_code, game_params)
  end

  def start_game(game_code) do
    Server.start(game_code)
  end

  def stop_game(game_code) do
    Server.stop(game_code, :normal)
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

  def skip_question(game_code) do
    Server.skip(game_code)
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

  def generate_code do
    :rand.uniform(999) |> Integer.to_string() |> String.pad_leading(3, "0")
  end
end
