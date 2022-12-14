defmodule TauperWeb.GameLive do
  # use Phoenix.LiveView, layout: {TauperWeb.LayoutView, "live.html"}
  use TauperWeb, :live_view
  alias Tauper.Games
  alias TauperWeb.{Endpoint, Presence}
  alias Ecto.Changeset

  @game_topic "games"

  def can_player_join_game(game, current_player_name, current_game_code) do
    cond do
      game == nil ->
        {:error, %{message: "game does not exist"}}

      !current_player_name ->
        {:error, %{message: "missing player name"}}

      # current_game_code != game.code ->
      #   {:error, %{message: "invalid game code"}}

      Presence.is_player_already_in_game(current_game_code, current_player_name) ->
        {:error, %{message: "player already in game"}}

      true ->
        {:ok, "player can join the game"}
    end
  end

  def on_mount(:default, %{"id" => _id} = _params, session, socket) do
    player_name = session["current_player_name"]
    game_code = session["current_game_code"]
    game = Games.game(game_code)

    case can_player_join_game(game, player_name, game_code) do
      {:ok, _} ->
        {:cont,
         socket
         |> assign(:game, game)
         |> assign(:game_code, game_code)
         |> assign(:question, game.question.sentence)
         |> assign(:podium, Games.podium(game_code))
         |> assign(:changeset, change_answer())
         |> assign(:status, game.status)
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

  def mount(_params, session, socket) do
    if connected?(socket) do
      Endpoint.subscribe(@game_topic)
    end

    {:ok, socket}
  end

  def handle_params(%{"id" => id}, _, socket) do
    game_code = socket.assigns.game_code
    players = Presence.list_players(game_code)
    current_player_name = socket.assigns.player_name
    maybe_track_player(game_code, socket, current_player_name)

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

  def handle_info(%{event: "next_question"}, socket) do
    game_code = socket.assigns.game_code
    game = Games.game(game_code)

    {:noreply,
     socket
     |> assign(:question, game.question.sentence)}
  end

  def handle_info(%{event: "game_status_changed"} = data, socket) do
    game_code = socket.assigns.game_code
    new_status = data.payload.status
    podium = if new_status == :game_over, do: Games.podium(game_code), else: []

    {:noreply,
     socket
     |> assign(:status, new_status)
     |> assign(:podium, podium)}
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

  def handle_event("start", _data, socket) do
    game_code = socket.assigns.game_code
    game = Games.start_game(game_code)
    {:noreply, assign(socket, status: game.status, question: game.question.sentence)}
  end

  def handle_event("next", _data, socket) do
    game_code = socket.assigns.game_code
    game = Games.next_question(game_code)

    podium =
      case(game.status) do
        :game_over -> Games.podium(game_code)
        _ -> []
      end

    {:noreply,
     assign(socket, status: game.status, question: game.question.sentence, podium: podium)}
  end

  def handle_event("answer", %{"answer-form" => %{"answer" => answer}}, socket) do
    game_code = socket.assigns.game_code
    player_name = socket.assigns.player_name
    game = Games.answer(game_code, answer, player_name)

    {:noreply, assign(socket, status: game.status, question: game.question.sentence)}
  end
end
