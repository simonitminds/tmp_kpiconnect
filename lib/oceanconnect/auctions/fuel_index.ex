defmodule Oceanconnect.Auctions.FuelIndex do
  use Ecto.Schema
  import Ecto.{Changeset, Query}

  alias Oceanconnect.Auctions.{Fuel, Port}

  @derive {Poison.Encoder, except: [:__meta__, :fuel, :port]}

  schema "fuel_index_entries" do
    field :code, :string
    field :name, :string
    field :is_active, :boolean, default: true

    belongs_to :fuel, Fuel
    belongs_to :port, Port

    timestamps()
  end

  @doc false
  def changeset(%__MODULE__{} = fuel_index, attrs) do
    fuel_index
    |> cast(attrs, [:code, :name, :is_active, :fuel_id, :port_id])
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
