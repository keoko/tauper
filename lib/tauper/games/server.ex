defmodule Tauper.Games.Server do
  use GenServer
  alias TauperWeb.{Endpoint, Presence}

  @registry :game_registry

  @question_types ["symbol", "name", "oxidation_states"]

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
    status: :not_started,
    score: %{},
    timer: nil,
    remaining_time: @default_question_max_time,
    question_max_time: @default_question_max_time
  }

  # TODO load all elements
  # TODO does it make sense to have it in another file?
  # TODO cnaviar oxidatoin_states per valiencia
  @elements %{
    1 => %{symbol: "H", name: "Hidrogen", oxidation_states: [1], group: 1},
    2 => %{symbol: "He", name: "Heli", oxidation_states: [0], group: 18},
    3 => %{symbol: "Li", name: "Liti", oxidation_states: [1], group: 1},
    4 => %{symbol: "Be", name: "Beril·li", oxidation_states: [2], group: 2},
    5 => %{symbol: "B", name: "Bor", oxidation_states: [1, 2, 3], group: 13},
    6 => %{symbol: "C", name: "Carboni", oxidation_states: [1, 2, 3, 4], group: 14},
    7 => %{symbol: "N", name: "Nitrogen", oxidation_states: [1, 2, 3, 4, 5], group: 15},
    8 => %{symbol: "O", name: "Oxigen", oxidation_states: [1, 2], group: 16},
    9 => %{symbol: "F", name: "Fluor", oxidation_states: [1], group: 17},
    10 => %{symbol: "Ne", name: "Neó", oxidation_states: [0], group: 18},
    11 => %{symbol: "Na", name: "Sodi", oxidation_states: [1], group: 1},
    12 => %{symbol: "Mg", name: "Magnesi", oxidation_states: [1, 2], group: 2},
    13 => %{symbol: "Al", name: "Alumini", oxidation_states: [1, 3], group: 13},
    14 => %{symbol: "Si", name: "Silici", oxidation_states: [1, 2, 3, 4], group: 14},
    15 => %{symbol: "P", name: "Fòsfor", oxidation_states: [1, 2, 3, 4, 5], group: 15},
    16 => %{symbol: "S", name: "Sofre", oxidation_states: [1, 2, 3, 4, 5, 6], group: 16},
    17 => %{symbol: "Cl", name: "Clor", oxidation_states: [1, 2, 3, 4, 5, 6, 7], group: 17},
    18 => %{symbol: "Ar", name: "Argó", oxidation_states: [0], group: 18},
    19 => %{symbol: "K", name: "Potassi", oxidation_states: [1], group: 1},
    20 => %{symbol: "Ca", name: "Calci", oxidation_states: [2], group: 2},
    21 => %{symbol: "Sc", name: "Escandi", oxidation_states: [1, 2, 3], group: 3},
    22 => %{symbol: "Ti", name: "Titani", oxidation_states: [1, 2, 3, 4], group: 4},
    23 => %{symbol: "V", name: "Vanadi", oxidation_states: [1, 2, 3, 4], group: 5},
    24 => %{symbol: "Cr", name: "Cron", oxidation_states: [1, 2, 3, 4, 5, 6], group: 6},
    25 => %{symbol: "Mn", name: "Manganès", oxidation_states: [1, 2, 3, 4, 5, 6, 7], group: 7},
    26 => %{symbol: "Fe", name: "Ferro", oxidation_states: [1, 2, 3, 4, 5, 6], group: 8},
    27 => %{symbol: "Co", name: "Cobalt", oxidation_states: [1, 2, 3, 4, 5], group: 9},
    28 => %{symbol: "Ni", name: "Niquel", oxidation_states: [1, 2, 3, 4], group: 10},
    29 => %{symbol: "Cu", name: "Coure", oxidation_states: [1, 2, 3, 4], group: 11},
    30 => %{symbol: "Zn", name: "Zinc", oxidation_states: [2], group: 12},
    31 => %{symbol: "Ga", name: "Gal·li", oxidation_states: [1, 2, 3], group: 13},
    32 => %{symbol: "Ge", name: "Germani", oxidation_states: [1, 2, 3, 4], group: 14},
    33 => %{symbol: "As", name: "Arsènic", oxidation_states: [2, 3, 5], group: 15},
    34 => %{symbol: "Se", name: "Seleni", oxidation_states: [2, 4, 6], group: 16},
    35 => %{symbol: "Br", name: "Brom", oxidation_states: [1, 3, 4, 5, 7], group: 17},
    36 => %{symbol: "Kr", name: "Criptó", oxidation_states: [2], group: 18},
    37 => %{symbol: "Rb", name: "Rubidi", oxidation_states: [1], group: 1},
    38 => %{symbol: "Sr", name: "Estronci", oxidation_states: [2], group: 2},
    39 => %{symbol: "Y", name: "Itri", oxidation_states: [1, 2, 3], group: 3},
    40 => %{symbol: "Zr", name: "Zirconi", oxidation_states: [1, 2, 3, 4], group: 4},
    41 => %{symbol: "Nb", name: "Niobi", oxidation_states: [1, 2, 3, 4, 5], group: 5},
    42 => %{symbol: "Mo", name: "Molibdè", oxidation_states: [1, 2, 3, 4, 5, 6], group: 6},
    43 => %{symbol: "Tc", name: "Tecneci", oxidation_states: [1, 2, 3, 4, 5, 6, 7], group: 7},
    44 => %{symbol: "Ru", name: "Ruteni", oxidation_states: [1, 2, 3, 4, 5, 6, 7, 8], group: 8},
    45 => %{symbol: "Rh", name: "Rodi", oxidation_states: [1, 2, 3, 4, 5, 6], group: 9},
    46 => %{symbol: "Pd", name: "Pal·ladi", oxidation_states: [2, 4], group: 10},
    47 => %{symbol: "Ag", name: "Argent", oxidation_states: [1, 2, 3], group: 11},
    48 => %{symbol: "Cd", name: "Cadmi", oxidation_states: [2], group: 12},
    49 => %{symbol: "In", name: "Indi", oxidation_states: [1, 2, 3], group: 13},
    50 => %{symbol: "Sn", name: "Estany", oxidation_states: [2, 4], group: 14},
    51 => %{symbol: "Sb", name: "Antimoni", oxidation_states: [3, 5], group: 15},
    52 => %{symbol: "Te", name: "Tel·luri", oxidation_states: [2, 4, 5, 6], group: 16},
    53 => %{symbol: "I", name: "Iode", oxidation_states: [1, 3, 5, 7], group: 17},
    54 => %{symbol: "Xe", name: "Xenó", oxidation_states: [2, 4, 6, 8], group: 18},
    55 => %{symbol: "Cs", name: "Cesi", oxidation_states: [1], group: 1},
    56 => %{symbol: "Ba", name: "Bari", oxidation_states: [2], group: 2},
    57 => %{symbol: "La", name: "Lantani", oxidation_states: [2, 3], group: 3},
    58 => %{symbol: "Ce", name: "Ceri", oxidation_states: [2, 3, 4], group: 4},
    59 => %{symbol: "Pr", name: "Praseodimi", oxidation_states: [2, 3, 4], group: 5},
    60 => %{symbol: "Nd", name: "Neodimi", oxidation_states: [2, 3], group: 6},
    61 => %{symbol: "Pm", name: "Prometi", oxidation_states: [3], group: 7},
    62 => %{symbol: "Sm", name: "Samari", oxidation_states: [2, 3], group: 8},
    63 => %{symbol: "Eu", name: "Europi", oxidation_states: [2, 3], group: 9},
    64 => %{symbol: "Gd", name: "Gadolini", oxidation_states: [1, 2, 3], group: 10},
    65 => %{symbol: "Tb", name: "Terbi", oxidation_states: [1, 3, 4], group: 11},
    66 => %{symbol: "Dy", name: "Disprosi", oxidation_states: [2, 3], group: 12},
    67 => %{symbol: "Ho", name: "Holmi", oxidation_states: [3], group: 13},
    68 => %{symbol: "Er", name: "Erbi", oxidation_states: [3], group: 14},
    69 => %{symbol: "Tm", name: "Tuli", oxidation_states: [2, 3], group: 15},
    70 => %{symbol: "Yb", name: "Iterbi", oxidation_states: [2, 3], group: 16},
    71 => %{symbol: "Lu", name: "Luteci", oxidation_states: [3], group: 17},
    72 => %{symbol: "Hf", name: "Hafni", oxidation_states: [2, 3, 4], group: 4},
    73 => %{symbol: "Ta", name: "Tàntal", oxidation_states: [1, 2, 3, 4, 5], group: 5},
    74 => %{symbol: "W", name: "Tungstè", oxidation_states: [1, 2, 3, 4, 5, 6], group: 6},
    75 => %{symbol: "Re", name: "Reni", oxidation_states: [1, 2, 3, 4, 5, 6, 7], group: 7},
    76 => %{symbol: "Os", name: "Osmi", oxidation_states: [1, 2, 3, 4, 5, 6, 7, 8], group: 8},
    77 => %{symbol: "Ir", name: "Iridi", oxidation_states: [1, 2, 3, 4, 5, 6], group: 9},
    78 => %{symbol: "Pt", name: "Platí", oxidation_states: [2, 4, 5, 6], group: 10},
    79 => %{symbol: "Au", name: "Or", oxidation_states: [1, 2, 3, 5], group: 11},
    80 => %{symbol: "Hg", name: "Mercuri", oxidation_states: [1, 2, 4], group: 12},
    81 => %{symbol: "Tl", name: "Tal·li", oxidation_states: [1, 3], group: 13},
    82 => %{symbol: "Pb", name: "Plom", oxidation_states: [2, 4], group: 14},
    83 => %{symbol: "Bi", name: "Bismut", oxidation_states: [3, 5], group: 15},
    84 => %{symbol: "Po", name: "Poloni", oxidation_states: [2, 4, 6], group: 16},
    85 => %{symbol: "At", name: "Àstat", oxidation_states: [1, 3, 5], group: 17},
    86 => %{symbol: "Rn", name: "Radó", oxidation_states: [2], group: 18},
    87 => %{symbol: "Fr", name: "Franci", oxidation_states: [1], group: 1},
    88 => %{symbol: "Ra", name: "Radi", oxidation_states: [2], group: 2},
    89 => %{symbol: "Ac", name: "Actini", oxidation_states: [3], group: 3},
    90 => %{symbol: "Th", name: "Tori", oxidation_states: [2, 3, 4], group: 4},
    91 => %{symbol: "Pa", name: "Protoactini", oxidation_states: [3, 4, 5], group: 5},
    92 => %{symbol: "U", name: "Urani", oxidation_states: [3, 4, 5, 6], group: 6},
    93 => %{symbol: "Np", name: "Neptuni", oxidation_states: [3, 4, 5, 6, 7], group: 7},
    94 => %{symbol: "Pu", name: "Plutoni", oxidation_states: [3, 4, 5, 6, 7], group: 8},
    95 => %{symbol: "Am", name: "Amerci", oxidation_states: [2, 3, 4, 5, 6], group: 9},
    96 => %{symbol: "Cm", name: "Curi", oxidation_states: [3, 4], group: 10},
    97 => %{symbol: "Bk", name: "Berkeli", oxidation_states: [3, 4], group: 11},
    98 => %{symbol: "Cf", name: "Californi", oxidation_states: [2, 3, 4], group: 12},
    99 => %{symbol: "Es", name: "Einsteini", oxidation_states: [2, 3], group: 13},
    100 => %{symbol: "Fm", name: "Fermi", oxidation_states: [2, 3], group: 14},
    101 => %{symbol: "Md", name: "Mendelevi", oxidation_states: [2, 3], group: 15},
    102 => %{symbol: "No", name: "Nobeli", oxidation_states: [2, 3], group: 16},
    103 => %{symbol: "Lr", name: "Lawrenci", oxidation_states: [3], group: 17},
    104 => %{symbol: "Rf", name: "Rutherfordi", oxidation_states: [4], group: 4},
    105 => %{symbol: "Db", name: "Dubni", oxidation_states: [0], group: 5},
    106 => %{symbol: "Sg", name: "Seaborgi", oxidation_states: [0], group: 6},
    107 => %{symbol: "Bh", name: "Bohri", oxidation_states: [0], group: 7},
    108 => %{symbol: "Hs", name: "Hassi", oxidation_states: [0], group: 8},
    109 => %{symbol: "Mt", name: "Meitneri", oxidation_states: [0], group: 9},
    110 => %{symbol: "Ds", name: "Darmstadti", oxidation_states: [0], group: 10},
    111 => %{symbol: "Rg", name: "Roentgeni", oxidation_states: [0], group: 11},
    112 => %{symbol: "Cn", name: "Copernici", oxidation_states: [0], group: 12},
    113 => %{symbol: "Nh", name: "Nihoni", oxidation_states: [0], group: 13},
    114 => %{symbol: "Fl", name: "Flerovi", oxidation_states: [0], group: 14},
    115 => %{symbol: "Mc", name: "Moscovi", oxidation_states: [0], group: 15},
    116 => %{symbol: "Lv", name: "Livermori", oxidation_states: [0], group: 16},
    117 => %{symbol: "Ts", name: "Tennes", oxidation_states: [0], group: 17},
    118 => %{symbol: "Og", name: "Oganessó", oxidation_states: [0], group: 18}
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

  def podium(process_name, num_players \\ 5) do
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

  defp build_questions(num_questions, params \\ []) do
    all_questions =
      for question_type <- question_types(params),
          atomic_number <- atomic_numbers(params),
          do: %{type: question_type, atomic_number: atomic_number}

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

    @elements
    |> Enum.filter(fn {_k, v} -> v.group in groups end)
    |> Enum.map(fn {k, _v} -> k end)
  end

  defp build_sentence(question) do
    element = get_element(question.atomic_number)

    case question.type do
      "symbol" -> "Quin es el símbol del #{element.name}?"
      "name" -> "Quin es el nom del #{element.symbol}?"
      "oxidation_states" -> "Quin són els estats d'oxidació del #{element.name}?"
    end
  end

  defp shuffle_questions(questions) do
    Enum.shuffle(questions)
  end

  defp is_correct(question, answer) do
    element = get_element(question.atomic_number)

    correct_answer =
      case question.type do
        "symbol" -> element.symbol
        "name" -> element.name
        "oxidation_states" -> element.oxidation_states
      end

    correct_answer == answer
  end

  defp get_element(atomic_number) do
    @elements[atomic_number]
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

  defp calculate_podium(state, num_players) do
    state.score
    |> calculate_score
    |> sort_by_score
    |> Enum.take(num_players)
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

      _ ->
        state
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
end
