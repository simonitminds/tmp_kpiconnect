defmodule Oceanconnect.Auctions.Fuel do
  use Ecto.Schema
  import Ecto.{Changeset, Query}
  alias Oceanconnect.Auctions.Fuel


  @derive {Poison.Encoder, except: [:__meta__]}

  schema "fuels" do
    field :name, :string
		field :is_active, :boolean, default: true

    timestamps()
  end

  @doc false
  def changeset(%Fuel{} = fuel, attrs) do
    fuel
    |> cast(attrs, [:name, :is_active])
    |> validate_required([:name])
  end

	def select_active do
		from f in Fuel,
		  where: f.is_active == true
	end

	def alphabetical do
		from f in Fuel,
		  order_by: [asc: f.name]
	end
end
