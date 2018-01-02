defmodule Oceanconnect.Auctions.Fuel do
  use Ecto.Schema
  import Ecto.Changeset
  alias Oceanconnect.Auctions.Fuel


  @derive {Poison.Encoder, except: [:__meta__]}

  schema "fuels" do
    field :name, :string

    timestamps()
  end

  @doc false
  def changeset(%Fuel{} = fuel, attrs) do
    fuel
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end