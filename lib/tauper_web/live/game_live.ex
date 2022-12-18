defmodule TauperWeb.GameLive do
  # use Phoenix.LiveView, layout: {TauperWeb.LayoutView, "live.html"}
  use TauperWeb, :live_view
  alias Tauper.Games
  alias TauperWeb.{Endpoint, Presence}
  alias Ecto.Changeset

  def can_player_join_game(player_name, code, session) do
    cond do
      !player_name ->
        {:error, %{message: "missing player name"}}

      code != session["code"] ->
        {:error,
         %{
           message:
             "Invalid game code. You probably joined to a different game. Please join the game again."
         }}

      Games.lookup(code) == [] ->
        {:error, %{message: "game does not exist"}}

      # current_game_code != game.code ->
      #   {:error, %{message: "invalid game code"}}

      Presence.is_player_already_in_game(code, player_name) ->
        {:error, %{message: "player already in game"}}

      true ->
        {:ok, "player can join the game"}
    end
  end

  def on_mount(:default, %{"code" => code} = _params, session, socket) do
    player_name = session["player_name"]

    case can_player_join_game(player_name, code, session) do
      {:ok, _} ->
        game = Games.game(code)

        {:cont,
         socket
         |> assign(:game_code, code)
         |> assign(
           :question,
           if(!is_nil(game["question"]), do: game.question.sentence, else: nil)
         )
         |> assign(:podium, Games.podium(code))
         |> assign(:changeset, change_answer())
         |> assign(:status, game.status)
         |> assign(:remaining_time, game.remaining_time)
         |> assign(:player_name, player_name)}

      {:error, error} ->
        # add flash message
        #
        {:halt,
         socket
         |> put_flash(:error, error.message)
         |> redirect(to: "/join")}
    end
  end

  def mount(_params, _session, socket) do
    if connected?(socket) do
      code = socket.assigns.game_code
      Endpoint.subscribe(Presence.topic(code))
    end

    {:ok, socket}
  end

  def handle_params(%{"code" => code}, _, socket) do
    players = Presence.list_players(code)
    player_name = socket.assigns.player_name
    maybe_track_player(code, socket, player_name)

    {:noreply,
     socket
     |> assign(:players, players)}
  end

  @spec random_string :: bitstring
  def random_string do
    for _ <- 1..10, into: "", do: <<Enum.random('0123456789abcdef')>>
  end

  def maybe_track_player(
        game_code,
        socket,
        player_name
      ) do
    if connected?(socket) do
      Presence.track_player(self(), game_code, player_name)
    end
  end

  def handle_info(%{event: "presence_diff"}, socket) do
    game_code = socket.assigns.game_code
    players = Presence.list_players(game_code)

    {:noreply,
     socket
     |> assign(:players, players)}
  end

  def handle_info(%{event: "game_status_changed"} = data, socket) do
    game_code = socket.assigns.game_code
    new_status = data.payload.status
    game = Games.game(game_code)
    podium = if new_status == :game_over, do: Games.podium(game_code), else: []

    {:noreply,
     socket
     |> assign(:question, game.question.sentence)
     |> assign(:status, new_status)
     |> assign(:podium, podium)}
  end

  def handle_info(%{event: "next_question"}, socket) do
    game_code = socket.assigns.game_code
    game = Games.game(game_code)

    {:noreply,
     socket
     |> assign(:status, game.status)
     |> assign(:question, game.question.sentence)}
  end

  def handle_info(%{event: "question_tick", payload: payload}, socket) do
    {:noreply,
     socket
     |> assign(:remaining_time, payload.remaining_time)}
  end

  def handle_info(%{event: "question_timeout"}, socket) do
    {:noreply,
     socket
     |> assign(:remaining_time, "timeout")}
  end

  def handle_info(_event, socket) do
    {:noreply, socket}
  end

  def change_answer(attrs \\ %{}) do
    types = %{
      answer: :string
    }

    # apply_action(:insert) needed to display error messages in the form
    {%{}, types}
    |> Changeset.cast(attrs, Map.keys(types))
    |> Changeset.validate_required([:answer])
    |> Changeset.validate_length(:answer, min: 1, max: 50)
  end

  def handle_event("answer", %{"answer-form" => %{"answer" => answer}}, socket) do
    game_code = socket.assigns.game_code
    player_name = socket.assigns.player_name
    game = Games.answer(game_code, answer, player_name)

    {:noreply, assign(socket, status: game.status, question: game.question.sentence)}
  end
end
