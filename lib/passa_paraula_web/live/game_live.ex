defmodule PassaParaulaWeb.GameLive do
  use Phoenix.LiveView, layout: {PassaParaulaWeb.LayoutView, "live.html"}
  alias PassaParaula.Games
  alias PassaParaulaWeb.{Endpoint, Presence}

  @game_topic "games"

  def can_player_join_game(game, current_player_name, current_game_code) do
    cond do
      game == nil ->
        {:error, %{message: "game does not exist"}}

      !current_player_name ->
        {:error, %{message: "missing player name"}}

      current_game_code != game.code ->
        {:error, %{message: "invalid game code"}}

      Presence.is_player_already_in_game(game.code, current_player_name) ->
        {:error, %{message: "player already in game"}}

      true ->
        {:ok, "player can join the game"}
    end
  end

  def on_mount(:default, %{"id" => id} = _params, session, socket) do
    current_player_name = session["current_player_name"]
    current_game_code = session["current_game_code"]
    game = Games.get_game(id)

    case can_player_join_game(game, current_player_name, current_game_code) do
      {:ok, _} ->
        {:cont,
         socket
         |> assign(:game, game)
         |> assign(:current_player_name, current_player_name)}

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
    game = socket.assigns.game
    players = Presence.list_players(game.code)
    current_player_name = socket.assigns.current_player_name
    maybe_track_player(game, socket, current_player_name)

    {:noreply,
     socket
     |> assign(:game, game)
     |> assign(:players, players)}
  end

  def render(assigns) do
    ~H"""
    <h1>Game</h1>

    <ul>

    <li>
    <strong>Code:</strong>
    <%= @game.code %>
    </li>

    <li>
    <strong>Status:</strong>
    <%= @game.status %>
    </li>

    <li>
    <strong>Players:</strong>
        <ul>
        <%= for player <- @players do %>
        <li><%= player.name %> </li>
        <% end %>
        </ul>
    </li>
    </ul>

    <button>Start Game</button>
    """
  end

  def random_string do
    for _ <- 1..10, into: "", do: <<Enum.random('0123456789abcdef')>>
  end

  def maybe_track_player(
        game,
        socket,
        current_player_name
      ) do
    if connected?(socket) do
      Presence.track_player(self(), game, current_player_name)
    end
  end

  def handle_info(%{event: "presence_diff"}, socket) do
    game = socket.assigns.game
    players = Presence.list_players(game.code)

    {:noreply,
     socket
     |> assign(:players, players)}
  end
end
