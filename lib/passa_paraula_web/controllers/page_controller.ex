defmodule PassaParaulaWeb.PageController do
  use PassaParaulaWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
