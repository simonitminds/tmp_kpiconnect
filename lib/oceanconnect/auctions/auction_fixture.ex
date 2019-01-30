defmodule Oceanconnect.Auctions.AuctionFixture do
  use Ecto.Schema
  import Ecto.Query, warn: false
  import Ecto.Changeset
  alias __MODULE__
  alias Oceanconnect.Auctions.{AuctionVesselFuel, Auction}

  schema "auction_fixtures" do
    # current_relationships
    belongs_to(:auction, Oceanconnect.Auctions.Auction)
    belongs_to(:supplier, Oceanconnect.Accounts.Company)
    belongs_to(:vessel, Oceanconnect.Auctions.Vessel)
    belongs_to(:fuel, Oceanconnect.Auctions.Fuel)

    # current fields
    field(:price, :integer)
    field(:quantity, :integer)
    field(:eta, :utc_datetime_usec)
    field(:etd, :utc_datetime_usec)

    # original_relationships
    belongs_to(:original_supplier, Oceanconnect.Accounts.Company, foreign_key: :original_supplier_id)
    belongs_to(:original_vessel, Oceanconnect.Auctions.Vessel, foreign_key: :original_vessel_id)
    belongs_to(:original_fuel, Oceanconnect.Auctions.Fuel, foreign_key: :original_fuel_id)

    # original_fields
    field(:original_quantity, :integer)
    field(:original_eta, :utc_datetime_usec)
    field(:original_etd, :utc_datetime_usec)
    field(:original_price, :integer)
  end

  def changeset(%AuctionFixture{} = auction_fixture, attrs) do
    auction_fixture
    |> cast(attrs, [
      :auction_id,
      :supplier_id,
      :vessel_id,
      :fuel_id,
      :price,
      :quantity,
      :eta,
      :etd,
      :original_supplier_id,
      :original_vessel_id,
      :original_fuel_id,
      :original_price,
      :original_quantity,
      :original_eta,
      :original_etd
    ])
    |> validate_required([
      :auction_id,
      :supplier_id,
      :vessel_id,
      :fuel_id,
      :price,
      :quantity,
      :eta,
      :etd,
      :original_supplier_id,
      :original_vessel_id,
      :original_fuel_id,
      :original_price,
      :original_quantity,
      :original_eta,
      :original_etd
    ])
    |> foreign_key_constraint(:auction_id)
    |> foreign_key_constraint(:supplier_id)
    |> foreign_key_constraint(:fuel_id)
    |> foreign_key_constraint(:vessel_id)
    |> foreign_key_constraint(:original_supplier_id)
    |> foreign_key_constraint(:original_fuel_id)
    |> foreign_key_constraint(:original_vessel_id)
  end

  def from_auction_vessel_fuel(%AuctionVesselFuel{auction_id: auction_id,
                                                  vessel_id: vessel_id,
                                                  fuel_id: fuel_id,
                                                 }) do
    from(af in AuctionFixture,
      where: af.vessel_id == ^vessel_id and
        af.fuel_id == ^fuel_id and
        af.auction_id == ^auction_id
    )
  end

  def from_auction(%Auction{id: auction_id}) do
    from(af in AuctionFixture,
      where: af.auction_id == ^auction_id
    )
  end
end
