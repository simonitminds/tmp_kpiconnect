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

  def changeset(%AuctionVesselFuel{} = auction_vessel_fuel, attrs) do
    auction_vessel_fuel
    |> cast(attrs, [:vessel_id, :fuel_id, :auction_id, :quantity])
    |> validate_required([:fuel_id, :auction_id, :vessel_id, :quantity])
    |> foreign_key_constraint(:auction_id)
    |> foreign_key_constraint(:vessel_id)
    |> foreign_key_constraint(:fuel_id)
  end

  def changeset_for_new(%AuctionVesselFuel{} = auction_vessel_fuel, attrs) do
    auction_vessel_fuel
    |> cast(attrs, [:vessel_id, :fuel_id, :auction_id, :quantity])
    |> validate_required([:fuel_id, :vessel_id, :quantity])
    |> foreign_key_constraint(:vessel_id)
    |> foreign_key_constraint(:fuel_id)
  end

  def changeset_for_draft(%AuctionVesselFuel{} = auction_vessel_fuel, attrs) do
    auction_vessel_fuel
    |> cast(attrs, [:vessel_id, :fuel_id, :auction_id, :quantity])
    |> validate_vessel_or_fuel()
    |> foreign_key_constraint(:vessel_id)
    |> foreign_key_constraint(:fuel_id)
  end

  defp validate_vessel_or_fuel(changeset) do
    case get_field(changeset, :vessel_id) || get_field(changeset, :fuel_id) do
      nil ->
        add_error(changeset, :vessel_id, "at least one of vessel_id or fuel_id must be given")
        add_error(changeset, :fuel_id, "at least one of vessel_id or fuel_id must be given")
      _ -> changeset
    end
  end
end
