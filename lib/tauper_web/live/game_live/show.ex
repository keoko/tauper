defmodule TauperWeb.GameLive.Show do
  use TauperWeb, :live_view
  alias Tauper.Games
  alias TauperWeb.{Presence, Endpoint}
  alias TauperWeb.GameLive.Component
  alias Tauper.Email.{Recipient, ScoreEmail}
  alias Ecto.Changeset

  @podium_places 5

  def can_player_join_game(player_name, code, session) do
    cond do
      !player_name ->
        {:error, %{message: "missing player name"}}

      player_name != "owner" ->
        {:error, %{message: "only owner of the game can open this page"}}

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
         |> assign(:question, game.question)
         |> assign(:game, game)
         |> assign(:podium, Games.podium(code))
         |> assign(:changeset, change_answer())
         |> assign(:status, game.status)
         |> assign(:remaining_time, game.remaining_time)
         |> assign(:player_score_and_position, nil)
         |> assign(:player_name, player_name)}

      {:error, error} ->
        # add flash message
        #
        {:halt,
         socket
         |> put_flash(:error, error.message)
         |> redirect(to: Routes.page_path(socket, :index))}
    end
  end

  @impl true
  def mount(_params, %{"locale" => locale}, socket) do
    Gettext.put_locale(TauperWeb.Gettext, locale)

    if connected?(socket) do
      code = socket.assigns.game_code
      Endpoint.subscribe(Presence.topic(code))
    end

    {:ok,
     socket
     |> assign(:answers, nil)
     |> assign(:email_recipient, %Recipient{})}
  end

  @impl true
  def handle_params(%{"code" => code}, _, socket) do
    players = Presence.list_players(code)

    {
      :noreply,
      socket
      |> assign(:code, code)
      |> assign(:players, players)
    }
  end

  @impl true
  def handle_info(%{event: "presence_diff"}, socket) do
    code = socket.assigns.code
    players = Presence.list_players(code)

    {:noreply,
     socket
     |> assign(:players, players)}
  end

  def handle_info(%{event: "question_tick", payload: payload}, socket) do
    {:noreply,
     socket
     |> assign(:remaining_time, payload.remaining_time)}
  end

  def handle_info(%{event: "question_answered", payload: payload}, socket) do
    {:noreply,
     socket
     |> assign(:answers, payload)}
  end

  def handle_info(%{event: "game_status_changed"} = data, socket) do
    game_code = socket.assigns.game_code
    player_name = socket.assigns.player_name
    new_status = data.payload.status
    game = Games.game(game_code)
    answered = if new_status in [:started, :game_over], do: false, else: socket.assigns.answered
    is_correct = if new_status in [:started, :game_over], do: nil, else: socket.assigns.is_correct
    podium = if new_status in [:paused, :game_over], do: Games.podium(game_code), else: []

    player_score_and_position =
      TauperWeb.GameLive.Play.get_player_score_and_position(player_name, podium)

    podium =
      if new_status in [:game_over, :paused],
        do: Games.podium(game_code, @podium_places),
        else: []

    {:noreply,
     socket
     |> assign(:question, game.question)
     |> assign(:game, game)
     |> assign(:answers, game.answers)
     |> assign(:remaining_time, game.remaining_time)
     |> assign(:answered, answered)
     |> assign(:is_correct, is_correct)
     |> assign(:status, new_status)
     |> assign(:podium, podium)
     |> assign(:player_score_and_position, player_score_and_position)}
  end

  def handle_info(_event, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("start", _data, socket) do
    code = socket.assigns.code
    game = Games.start_game(code)
    {:noreply, assign(socket, status: game.status, question: game.question)}
  end

  def handle_event("next", _data, socket) do
    code = socket.assigns.code
    game = Games.next_question(code)

    {:noreply, assign(socket, status: game.status, question: game.question)}
  end

  def handle_event("skip", _data, socket) do
    code = socket.assigns.code
    game = Games.skip_question(code)

    {:noreply, assign(socket, status: game.status, question: game.question)}
  end

  def handle_event("answer", %{"answer-form" => %{"answer" => answer}}, socket) do
    game_code = socket.assigns.game_code
    player_name = socket.assigns.player_name
    game = socket.assigns.game

    is_correct =
      case Games.answer(game_code, answer, player_name) do
        {:ok, %{is_correct: is_correct}} -> is_correct
        _ -> nil
      end

    # force skipping the question to jump to the "podium" page
    if game.alone do
      Games.skip_question(game_code)
    end

    {:noreply,
     socket
     |> assign(:is_correct, is_correct)
     |> assign(:answered, true)}
  end

  def handle_event("stop", _data, socket) do
    code = socket.assigns.code
    Games.stop_game(code)

    {:noreply, redirect(socket, to: Routes.page_path(socket, :index))}
  end

  def handle_event(
        "validate_score_email",
        %{"score-email-form" => recipient_params},
        %{assigns: %{email_recipient: recipient}} = socket
      ) do
    changeset =
      recipient
      |> Recipient.changeset(recipient_params)
      |> Map.put(:action, :validate)

    {:noreply,
     socket
     |> assign(:changeset, changeset)}
  end

  def handle_event("send_score_email", %{"score-email-form" => recipient_params}, socket) do
    email = recipient_params["email"]
    code = socket.assigns.code
    podium = Games.podium(code)

    socket =
      case ScoreEmail.send_score_email(email, code, podium) do
        {:ok, _} ->
          socket |> put_flash(:info, gettext("Email sent"))

        _ ->
          socket
          |> put_flash(
            :error,
            gettext("Email cannot be sent. There has been an unexpected error.")
          )
      end

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
end
