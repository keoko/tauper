defmodule TauperWeb.Presence do
  @moduledoc """
  Provides presence tracking to channels and processes.


  See the [`Phoenix.Presence`](https://hexdocs.pm/phoenix/Phoenix.Presence.html)
  docs for more details.
  """
  @game_topic "games"

  use Phoenix.Presence,
    otp_app: :tauper,
    pubsub_server: Tauper.PubSub

  def track_player(pid, game_code, player_name) do
    track(
      pid,
      @game_topic,
      game_code,
      %{players: [%{name: player_name}]}
    )
  end

  def is_player_already_in_game(game_code, player_name) do
    players = list_players(game_code)
    Enum.any?(players, fn x -> x.name == player_name end)
  end

  def list_players(game_code) do
    foo =
      list(@game_topic)
      |> Map.get(game_code)
      |> extract_players()
  end

  defp extract_players(%{metas: metas}) do
    players_from_metas_list(metas)
  end

  defp extract_players(_metas) do
    []
  end

  defp players_from_metas_list(metas_list) do
    Enum.map(metas_list, &players_from_meta_map/1)
    |> List.flatten()
    |> Enum.uniq()
  end

  defp players_from_meta_map(meta_map) do
    get_in(meta_map, [:players])
  end
end
