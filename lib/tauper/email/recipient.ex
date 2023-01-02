defmodule Tauper.Email.Recipient do
  defstruct [:email]

  @types %{email: :string}

  import Ecto.Changeset

  def changeset(%__MODULE__{} = recipient, attrs) do
    {recipient, @types}
    |> cast(attrs, Map.keys(@types))
    |> validate_required([:email])
    |> validate_format(:email, ~r/@/)
  end
end
