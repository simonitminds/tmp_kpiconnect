defmodule Oceanconnect.Auctions.AuctionVesselFuel do
  use Ecto.Schema
  import Ecto.{Changeset}
  alias __MODULE__

  @derive {Poison.Encoder, except: [:__meta__, :auction]}

  schema "auctions_vessels_fuels" do
    belongs_to(:auction, Oceanconnect.Auctions.Auction)
    belongs_to(:vessel, Oceanconnect.Auctions.Vessel)
    belongs_to(:fuel, Oceanconnect.Auctions.Fuel)
    field(:quantity, :integer)

    timestamps()
  end

  def changeset_for_new(%AuctionVesselFuel{} = auction_vessel_fuel, attrs) do
    auction_vessel_fuel
    |> cast(attrs, [:vessel_id, :fuel_id, :auction_id, :quantity])
    |> validate_required([:fuel_id, :vessel_id, :quantity])
    |> foreign_key_constraint(:vessel_id)
    |> foreign_key_constraint(:fuel_id)
  end

  def changeset(%AuctionVesselFuel{} = auction_vessel_fuel, attrs) do
    auction_vessel_fuel
    |> cast(attrs, [:vessel_id, :fuel_id, :auction_id, :quantity])
    |> validate_required([:fuel_id, :auction_id, :vessel_id, :quantity])
    |> foreign_key_constraint(:auction_id)
    |> foreign_key_constraint(:vessel_id)
    |> foreign_key_constraint(:fuel_id)
  end
end
