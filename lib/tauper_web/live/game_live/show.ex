defmodule TauperWeb.GameLive.Show do
  use TauperWeb, :live_view
  alias Tauper.Games
  alias TauperWeb.{Presence, Endpoint}
  alias TauperWeb.GameLive.Component

  @impl true
  def mount(_params, %{"locale" => locale}, socket) do
    Gettext.put_locale(TauperWeb.Gettext, locale)

    if connected?(socket) do
      code = socket.assigns.game_code
      Endpoint.subscribe(Presence.topic(code))
    end

    {:ok, socket |> assign(:answers, nil)}
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
    new_status = data.payload.status
    game = Games.game(game_code)
    podium = if new_status in [:game_over, :paused], do: Games.podium(game_code), else: []

    {:noreply,
     socket
     |> assign(:question, game.question)
     |> assign(:game, game)
     |> assign(:answers, game.answers)
     |> assign(:remaining_time, game.remaining_time)
     |> assign(:status, new_status)
     |> assign(:podium, podium)}
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
    podium = if game.status in [:game_over, :paused], do: Games.podium(code), else: []

    {:noreply, assign(socket, status: game.status, question: game.question, podium: podium)}
  end

  def handle_event("skip", _data, socket) do
    code = socket.assigns.code
    game = Games.skip_question(code)
    podium = if game.status in [:game_over, :paused], do: Games.podium(code), else: []

    {:noreply, assign(socket, status: game.status, question: game.question, podium: podium)}
  end

  def handle_event("stop", _data, socket) do
    code = socket.assigns.code
    Games.stop_game(code)

    {:noreply, redirect(socket, to: Routes.page_path(socket, :index))}
  end
end
