defmodule TauperWeb.GameLive.Show do
  use TauperWeb, :live_view
  alias Tauper.Games
  alias TauperWeb.{Presence, Endpoint}

  @game_topic "games"

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Endpoint.subscribe(@game_topic)
    end

    {:ok, socket}
  end

  @impl true
  def handle_params(%{"code" => code}, _, socket) do
    players = Presence.list_players(code)

    {
      :noreply,
      socket
      |> assign(:page_title, page_title(socket.assigns.live_action))
      |> assign(:code, code)
      |> assign(:players, players)
    }
  end

  def handle_event("start", _data, socket) do
    code = socket.assigns.code
    game = Games.start_game(code)
    {:noreply, assign(socket, status: game.status, question: game.question.sentence)}
  end

  def handle_info(%{event: "presence_diff"}, socket) do
    # def handle_info(event, socket) do
    code = socket.assigns.code
    players = Presence.list_players(code)

    {:noreply,
     socket
     |> assign(:players, players)}
  end

  def handle_event("next", _data, socket) do
    code = socket.assigns.code
    game = Games.next_question(code)
    podium = if game.status == :game_over, do: Games.podium(code), else: []

    {:noreply,
     assign(socket, status: game.status, question: game.question.sentence, podium: podium)}
  end

  def handle_event("stop", _data, socket) do
    code = socket.assigns.code
    Games.stop_game(code)

    {:noreply, redirect(socket, to: Routes.game_path(socket, :new))}
  end

  defp page_title(:show), do: "Show Game"
  defp page_title(:edit), do: "Edit Game"
end
