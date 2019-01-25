defmodule Oceanconnect.Auctions.AuctionFixture do
  use Ecto.Schema
  import Ecto.Query, warn: false
  import Ecto.Changeset
  alias __MODULE__
  alias Oceanconnect.Auctions.{AuctionVesselFuel, Auction}

  schema "auction_fixtures" do
    belongs_to(:auction, Oceanconnect.Auctions.Auction)
    belongs_to(:auction_vessel_fuel, Oceanconnect.Auctions.AuctionVesselFuel)
    belongs_to(:supplier, Oceanconnect.Accounts.Company)
    field(:winning_price, :integer)
    field(:post_auction_price, :integer)
    field(:post_auction_quantity)
  end

  def changeset(%AuctionFixture{} = auction_fixture, attrs) do
    auction_fixture
    |> cast(attrs, [
      :auction_id,
      :auction_vessel_fuel_id,
      :supplier_id,
      :winning_price,
      :post_auction_price,
      :post_auction_quantity
    ])
    |> validate_required([:auction_id, :auction_vessel_fuel_id, :supplier_id, :winning_price])
    |> foreign_key_constraint(:auction_id)
    |> foreign_key_constraint(:auction_vessel_fuel_id)
    |> foreign_key_constraint(:supplier_id)
  end

  def from_auction_vessel_fuel(%AuctionVesselFuel{id: avf_id}) do
    from af in AuctionFixture,
      where: af.auction_vessel_fuel_id == ^avf_id
  end

  def from_auction(%Auction{id: auction_id}) do
    from af in AuctionFixture,
      where: af.auction_id == ^auction_id
  end
end
