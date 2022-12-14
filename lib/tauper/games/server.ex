defmodule Tauper.Games.Server do
  use GenServer

  @registry :game_registry

  @initial_state %{questions: [], current_question: 0, status: :not_started, score: %{}}

  # TODO load all elements
  # TODO does it make sense to have it in another file?
  # TODO cnaviar oxidatoin_states per valiencia
  @elements %{
    1 => %{symbol: "H", name: "Hidrogen", oxidation_states: [1]},
    2 => %{symbol: "He", name: "Heli", oxidation_states: [0]},
    3 => %{symbol: "Li", name: "Liti", oxidation_states: [1]}
  }

  ## missing client API
  def start_link(name) do
    GenServer.start_link(__MODULE__, name, name: via_tuple(name))
  end

  def start(process_name) do
    call_server(process_name, :start_game)
  end

  def game(process_name) do
    call_server(process_name, :game)
  end

  def answer(process_name, answer, player) do
    call_server(process_name, {:answer, answer, player})
  end

  def next(process_name) do
    call_server(process_name, :next)
  end

  def score(process_name) do
    call_server(process_name, :score)
  end

  def podium(process_name, num_players \\ 5) do
    call_server(process_name, {:podium, num_players})
  end

  ## Defining GenServer callbacks
  @impl true
  def init(opts \\ []) do
    questions = build_questions(opts)

    state = %{@initial_state | questions: questions}

    {:ok, state}
  end

  @doc """
  This function will be called by the supervisor to retrieve the specification
  of the child process.The child process is configured to restart only if it
  terminates abnormally.
  """
  def child_spec(process_name) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [process_name]},
      restart: :transient
    }
  end

  def stop(process_name, stop_reason) do
    # Given the :transient option in the child spec, the GenServer will restart
    # if any reason other than `:normal` is given.
    process_name |> via_tuple() |> GenServer.stop(stop_reason)
  end

  @impl true
  def handle_call(:start_game, _from, state) do
    state = %{state | status: :started, current_question: 0}
    {:reply, status_details(state), state}
  end

  @impl true
  def handle_call(:game, _from, state) do
    # TODO handle game status?
    {:reply, status_details(state), state}
  end

  @impl true
  def handle_call({:answer, answer, player}, _from, state) do
    question = get_question(state)

    if has_already_answered(state, player) do
      # {:reply, %{is_correct: :already_answered, question: question}, state}
      {:reply, status_details(state), state}
    else
      is_correct = is_correct(question, answer)
      state = state |> update_score(player, is_correct)

      {:reply, status_details(state), state}
    end
  end

  @impl true
  def handle_call(:next, _from, state) do
    # TODO handle game status?
    state = next_question(state)
    {:reply, status_details(state), state}
  end

  @impl true
  def handle_call(:score, _from, state) do
    {:reply, state.score, state}
  end

  @impl true
  def handle_call({:podium, num_players}, _from, state) do
    {:reply, calculate_podium(state, num_players), state}
  end

  defp get_question(state) do
    Enum.at(state.questions, state.current_question)
  end

  defp next_question(state) do
    if is_last_question(state) do
      %{state | status: :game_over}
    else
      %{state | current_question: state.current_question + 1}
    end
  end

  def is_last_question(state) do
    state.current_question == Enum.count(state.questions) - 1
  end

  def build_questions(_opts \\ []) do
    # TODO build questions based on user-provided options
    # question_types = [:symbol, :name, :oxidation_states]
    # atomic_numbers = [1, 2, 3]
    question_types = [:symbol, :name]
    atomic_numbers = [1, 2]

    questions =
      for question_type <- question_types,
          atomic_number <- atomic_numbers,
          do: %{type: question_type, atomic_number: atomic_number}

    Enum.map(questions, fn q -> Map.put(q, :sentence, build_sentence(q)) end)
  end

  def build_sentence(question) do
    element = get_element(question.atomic_number)

    case question.type do
      :symbol -> "Quin es el símbol del #{element.name}?"
      :name -> "Quin es el nom del #{element.symbol}?"
      :oxidation_states -> "Quin són els estats d'oxidació del #{element.name}?"
    end
  end

  def shuffle_questions(questions) do
    Enum.shuffle(questions)
  end

  def is_correct(question, answer) do
    element = get_element(question.atomic_number)

    correct_answer =
      case question.type do
        :symbol -> element.symbol
        :name -> element.name
        :oxidation_states -> element.oxidation_states
      end

    correct_answer == answer
  end

  def get_element(atomic_number) do
    @elements[atomic_number]
  end

  def update_score(state, player, is_correct) do
    score = if is_correct, do: 1, else: 0

    state
    |> maybe_init_player_score(player)
    |> put_in([:score, player, state.current_question], score)
  end

  def maybe_init_player_score(state, player) do
    list_nils = Stream.repeatedly(fn -> nil end) |> Enum.take(length(state.questions))
    init_score = 0..length(list_nils) |> Stream.zip(list_nils) |> Enum.into(%{})

    if get_in(state, [:score, player]) != nil do
      state
    else
      update_in(state, [:score], &Map.put(&1, player, init_score))
    end
  end

  def calculate_podium(state, num_players) do
    state.score
    |> calculate_score
    |> sort_by_score
    |> Enum.take(num_players)
  end

  def calculate_score(m) do
    Enum.map(m, fn {k, v} -> {k, sum_points(v)} end)
  end

  def sum_points(m) do
    m |> Map.values() |> Enum.reject(&is_nil/1) |> Enum.sum()
  end

  def sort_by_score(m) do
    Enum.sort_by(m, fn {_k, v} -> v end, :desc)
  end

  def has_already_answered(state, player) do
    !is_nil(get_in(state, [:score, player, state.current_question]))
  end

  defp via_tuple(name) do
    {:via, Registry, {@registry, name}}
  end

  defp call_server(process_name, request) do
    process_name
    |> via_tuple()
    |> GenServer.call(request)
  end

  defp status_details(state) do
    state
    |> Map.delete(:questions)
    |> Map.put(:question, Enum.at(state.questions, state.current_question))
  end
end
