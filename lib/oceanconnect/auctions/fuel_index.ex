defmodule Oceanconnect.Auctions.FuelIndex do
  use Ecto.Schema
  import Ecto.{Changeset, Query}

  alias Oceanconnect.Auctions.{Fuel, Port}


  schema "fuel_index_entries" do
    field :code, :integer
    belongs_to :fuel, Fuel
    field :name, :string
    belongs_to :port, Port
    field :is_active, :boolean, default: true

    timestamps()
  end

  @doc false
  def changeset(%__MODULE__{} = fuel_index, attrs) do
    fuel_index
    |> cast(attrs, [:code, :name, :is_active])
    |> validate_required([:code, :name])
    |> cast_assoc(:fuel)
    |> cast_assoc(:port)
  end

  def select_active(query \\ __MODULE__) do
    from(
      q in query,
      where: q.is_active == true
    )
  end

  def alphabetical(query \\ __MODULE__) do
    from(
      q in query,
      order_by: q.name
    )
  end
end
