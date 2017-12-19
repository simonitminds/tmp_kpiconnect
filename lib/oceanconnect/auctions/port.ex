defmodule Oceanconnect.Auctions.Port do
  use Ecto.Schema
  import Ecto.Changeset
  alias Oceanconnect.Auctions.Port

  @derive {Poison.Encoder, except: [:__meta__]}
  schema "ports" do
    field :name, :string
    field :country, :string

    timestamps()
  end

  @doc false
  def changeset(%Port{} = port, attrs) do
    port
    |> cast(attrs, [:name, :country])
    |> validate_required([:name, :country])
  end
end
