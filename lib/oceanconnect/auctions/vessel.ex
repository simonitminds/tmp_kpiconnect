defmodule Oceanconnect.Auctions.Vessel do
  use Ecto.Schema
  import Ecto.Changeset
  alias Oceanconnect.Auctions.Vessel


  @derive {Poison.Encoder, except: [:__meta__]}

  schema "vessels" do
    field :imo, :integer
    field :name, :string

    timestamps()
  end

  @doc false
  def changeset(%Vessel{} = vessel, attrs) do
    vessel
    |> cast(attrs, [:name, :imo])
    |> validate_required([:name, :imo])
  end
end
