defmodule TauperWeb.Plugs.SessionToAssignPlug do
  import Plug.Conn

  def init(_opts), do: nil

  def call(conn, _opts) do
    code = get_session(conn, :code)
    player_name = get_session(conn, :player_name)

    conn
    |> assign(:current_code, code)
    |> assign(:current_player_name, player_name)
  end
end
