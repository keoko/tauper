defmodule Tauper.Games.Server do
  use GenServer

  ## missing client API
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def question(server) do
    GenServer.call(server, :question)
  end

  def answer(server, answer) do
    GenServer.call(server, {:answer, answer})
  end

  ## Defining GenServer callbacks
  @impl true
  def init(:ok) do
    questions = [
      %{letter: "a", question: "can grow to 13 feet (4 meters) long", answer: "alligator"},
      %{
        letter: "b",
        question:
          "live in pretty much every kind of place you can think of: hot jungles, forests, grasslands, mountains, and the freezing cold arctic.",
        answer: "bear"
      },
      %{letter: "c", question: "mixu-mixu", answer: "cat"}
    ]

    state = %{questions: questions, current_question: 0}

    {:ok, state}
  end

  @impl true
  def handle_call(:question, _from, state) do
    # TODO handle game status?
    {:reply, get_question_without_answer(state), state}
  end

  @impl true
  def handle_call({:answer, answer}, _from, state) do
    # TODO handle game status?
    # TODO check answer
    question = get_question(state)

    case question.answer == answer do
      true ->
        state = next_question(state)
        {:reply, %{response: :correct, question: get_question_without_answer(state)}, state}

      false ->
        {:reply, %{response: :wrong, question: get_question_without_answer(state)}, state}
    end
  end

  defp get_question(state) do
    Enum.at(state.questions, state.current_question)
  end

  defp get_question_without_answer(state) do
    get_question(state) |> Map.delete(:answer)
  end

  defp next_question(state) do
    %{state | current_question: state.current_question + 1}
  end

  def is_last_question(state) do
    state.current_question == Enum.count(state.questions) - 1
  end

  # @impl true
  # def handle_cast({:create, name}, names) do
  #   {:noreply, Map.put(names, name, "bucket_" <> name)}
  # end
end
