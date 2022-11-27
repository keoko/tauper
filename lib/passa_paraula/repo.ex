defmodule PassaParaula.Repo do
  use Ecto.Repo,
    otp_app: :passa_paraula,
    # adapter: Ecto.Adapters.Postgres
    adapter: Ecto.Adapters.SQLite3
end
