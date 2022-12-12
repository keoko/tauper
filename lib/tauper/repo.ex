defmodule Tauper.Repo do
  use Ecto.Repo,
    otp_app: :tauper,
    # adapter: Ecto.Adapters.Postgres
    adapter: Ecto.Adapters.SQLite3
end
