# defmodule TauperWeb.PlayerAuth do
#   import Plug.Conn
#   import Phoenix.Controller

#   @rand_size 32

#   def log_in_player(conn, player, params \\ %{}) do
#     token = generate_player_session_token(player)

#     conn
#     |> renew_session()
#     |> put_session(:player_token, token)
#     |> put_session(:live_socket_id, "players_sessions:#{Base.url_encode64(token)}")
#     |> redirect(to: user_return_to || signed_in_path(conn))
#   end

#   def generate_player_session_token(player) do
#     token = :crypto.strong_rand_bytes(@rand_size)
#   end
# end
