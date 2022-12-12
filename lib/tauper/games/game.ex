defmodule Tauper.Games.Game do
  use Ecto.Schema
  import Ecto.Changeset

  schema "games" do
    field :code, :string
    field :status, :string

    timestamps()
  end

  @doc false
  def changeset(game, attrs) do
    game
    |> cast(attrs, [:code, :status])
    |> validate_required([:code, :status])
    |> validate_inclusion(:status, ["started", "not_started", "completed"])
    |> validate_length(:code, is: 3)
    |> unsafe_validate_unique([:code], Tauper.Repo,
      message: "another game created with the same code"
    )
    |> unique_constraint(:code, name: :identifier_index)
  end
end
