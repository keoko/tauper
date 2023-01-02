defmodule Tauper.Games.Server do
  use GenServer
  alias TauperWeb.{Endpoint, Presence}
  import TauperWeb.Gettext
  alias Tauper.Games.Tables.EducemFar, as: Table

  @registry :game_registry

  @question_types ["symbol", "name", "valences"]

  @default_num_questions 20
  def default_num_questions, do: @default_num_questions

  @default_question_max_time 20
  def default_question_max_time, do: @default_question_max_time

  @max_num_groups 18

  @initial_state %{
    code: nil,
    questions: [],
    num_questions: @default_num_questions,
    current_question: 0,
    answer: nil,
    status: :not_started,
    score: %{},
    timer: nil,
    remaining_time: @default_question_max_time,
    question_max_time: @default_question_max_time
  }

  ## missing client API
  def start_link(opts) do
    code = Keyword.fetch!(opts, :code)
    params = Keyword.get(opts, :params, %{}) |> Map.put(:code, code)
    GenServer.start_link(__MODULE__, params, name: via_tuple(code))
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

  def skip(process_name) do
    call_server(process_name, :skip)
  end

  def score(process_name) do
    call_server(process_name, :score)
  end

  def podium(process_name, num_players \\ nil) do
    call_server(process_name, {:podium, num_players})
  end

  ## Defining GenServer callbacks
  @impl true
  def init(params \\ []) do
    question_max_time = params[:question_max_time] || @default_question_max_time
    num_questions = params[:num_questions] || @default_num_questions
    questions = build_questions(num_questions, params)

    state = %{
      @initial_state
      | code: params.code,
        questions: questions,
        num_questions: num_questions,
        question_max_time: question_max_time
    }

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
    state = next_question(%{state | current_question: -1})
    {:reply, status_details(state), state}
  end

  @impl true
  def handle_call(:game, _from, state) do
    {:reply, status_details(state), state}
  end

  @impl true
  def handle_call({:answer, answer, player}, _from, state) do
    question = get_question(state)

    if has_already_answered(state, player) do
      # {:reply, %{is_correct: :already_answered, question: question}, state}
      {:reply, {:error, :already_answered}, state}
    else
      is_correct = is_correct(question, answer)
      state = state |> update_score(player, is_correct)

      Endpoint.broadcast(
        Presence.topic(state.code),
        "question_answered",
        calculate_answers(state)
      )

      state =
        if all_plawers_answered_question(state) do
          change_status(state, :paused)
        else
          state
        end

      {:reply, {:ok, %{is_correct: is_correct}}, state}
    end
  end

  @impl true
  def handle_call(:next, _from, state) do
    state = next_question(state)

    {:reply, status_details(state), state}
  end

  def handle_call(:skip, _from, state) do
    state = change_status(state, :paused)

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

  @impl true
  def handle_info(:tick, state) do
    remaining_time = state.remaining_time - 1

    if remaining_time < 1 do
      {:noreply, %{state | remaining_time: remaining_time} |> change_status(:paused)}
    else
      Endpoint.broadcast(
        Presence.topic(state.code),
        "question_tick",
        %{
          remaining_time: remaining_time
        }
      )

      {:noreply, %{state | remaining_time: remaining_time}}
    end
  end

  defp get_question(state) do
    Enum.at(state.questions, state.current_question)
  end

  defp next_question(state) do
    if is_last_question(state) do
      change_status(state, :game_over)
    else
      %{
        state
        | current_question: state.current_question + 1,
          remaining_time: state.question_max_time
      }
      |> change_status(:started)
    end
  end

  defp is_last_question(state) do
    state.current_question == Enum.count(state.questions) - 1
  end

  defp build_questions(num_questions, params) do
    all_questions =
      for question_type <- question_types(params),
          atomic_number <- atomic_numbers(params),
          do: %{
            type: question_type,
            atomic_number: atomic_number,
            answer:
              Map.get(elements(), atomic_number)
              |> Map.get(String.to_existing_atom(question_type))
          }

    all_questions
    |> shuffle_questions()
    |> filter_num_questions(num_questions)
    |> Enum.map(fn q -> Map.put(q, :sentence, build_sentence(q)) end)
  end

  defp filter_num_questions(questions, num) do
    Enum.take(questions, num)
  end

  defp question_types(params) do
    types = params[:question_types] || @question_types

    Enum.reduce(types, [], fn v, acc ->
      if v in @question_types, do: [v | acc], else: acc
    end)
  end

  defp atomic_numbers(params) do
    groups = params[:element_groups] || Enum.to_list(1..@max_num_groups)

    elements()
    |> Enum.filter(fn {_k, v} -> v.group in groups end)
    |> Enum.map(fn {k, _v} -> k end)
  end

  defp build_sentence(question) do
    element = get_element(question.atomic_number)

    case question.type do
      "symbol" ->
        gettext("What is the symbol of %{element_name}?",
          element_name: element.name
        )

      "name" ->
        gettext("What is the name of %{element_symbol}?",
          element_symbol: element.symbol
        )

      "valences" ->
        gettext("What are the valences of %{element_name}?",
          element_name: element.name
        )
    end
  end

  defp shuffle_questions(questions) do
    Enum.shuffle(questions)
  end

  defp is_correct(question, answer) do
    element = get_element(question.atomic_number)

    case question.type do
      "symbol" -> is_correct_symbol(element.symbol, answer)
      "name" -> is_correct_name(element.name, answer)
      "valences" -> is_correct_valences(element.valences, answer)
    end
  end

  defp is_correct_symbol(symbol, answered_symbol) do
    symbol == answered_symbol
  end

  defp is_correct_name(name, answered_name) do
    String.downcase(name) == String.downcase(answered_name)
  end

  defp is_correct_valences(valences, answer) do
    try do
      answered_valences =
        answer
        |> String.split([",", " "])
        |> Enum.reject(&(&1 == ""))
        |> Enum.map(&String.to_integer/1)
        |> Enum.sort()

      valences == answered_valences
    rescue
      _ -> false
    end
  end

  defp get_element(atomic_number) do
    elements = elements()
    elements[atomic_number]
  end

  defp update_score(state, player, is_correct) do
    score = if is_correct, do: state.remaining_time, else: 0

    state
    |> maybe_init_player_score(player)
    |> put_in([:score, player, state.current_question], score)
  end

  defp maybe_init_player_score(state, player) do
    if get_in(state, [:score, player]) != nil do
      state
    else
      list_nils = Stream.repeatedly(fn -> nil end) |> Enum.take(length(state.questions))
      init_score = 0..length(list_nils) |> Stream.zip(list_nils) |> Enum.into(%{})

      update_in(state, [:score], &Map.put(&1, player, init_score))
    end
  end

  defp calculate_podium(state, num_players \\ nil) do
    state.score
    |> calculate_score
    |> sort_by_score
    |> case do
      score when num_players == nil -> score
      score -> Enum.take(score, num_players)
    end
  end

  defp calculate_score(m) do
    Enum.map(m, fn {k, v} -> {k, sum_points(v)} end)
  end

  defp sum_points(m) do
    m |> Map.values() |> Enum.reject(&is_nil/1) |> Enum.sum()
  end

  defp sort_by_score(m) do
    Enum.sort_by(m, fn {_k, v} -> v end, :desc)
  end

  defp has_already_answered(state, player) do
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
    |> Map.put(:answers, calculate_answers(state))
    |> Map.put(:question, Enum.at(state.questions, state.current_question))
  end

  defp change_status(state, new_status) do
    if state.status != new_status do
      Endpoint.broadcast(Presence.topic(state.code), "game_status_changed", %{status: new_status})
      %{state | status: new_status} |> update_timer()
    else
      state
    end
  end

  defp update_timer(state) do
    case state.status do
      :started ->
        start_timer(state)

      :paused ->
        stop_timer(state)

      :game_over ->
        stop_timer(state)
    end
  end

  defp start_timer(state) do
    {:ok, timer} = :timer.send_interval(:timer.seconds(1), self(), :tick)
    %{state | timer: timer}
  end

  defp stop_timer(state) do
    if !is_nil(state.timer) do
      {:ok, _cancel} = :timer.cancel(state.timer)
    end

    %{state | timer: nil}
  end

  defp all_plawers_answered_question(state) do
    # needed because state.score is only populoated when the player answers a question
    num_players = Presence.num_players(state.code)

    map_size(state.score) == num_players and
      Enum.all?(state.score, fn {_player, player_score} ->
        !is_nil(player_score[state.current_question])
      end)
  end

  defp calculate_answers(state) do
    num_players = num_players(state)

    num_answers =
      state.score
      |> Enum.filter(fn {_k, v} -> !is_nil(Map.get(v, state.current_question)) end)
      |> Enum.count()

    %{total_players: num_players, num_answers: num_answers}
  end

  defp num_players(state) do
    active_players = Presence.num_players(state.code)
    score_players = Enum.count(state.score)

    max(active_players, score_players)
  end

  defp elements, do: Table.elements()
end
