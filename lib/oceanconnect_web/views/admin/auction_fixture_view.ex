defmodule OceanconnectWeb.Admin.AuctionFixtureView do
  use OceanconnectWeb, :view
  alias Oceanconnect.Accounts.Company
  alias Oceanconnect.Auctions.{AuctionFixture, Fuel, Vessel}

  def auction_name(auction) do
    "auction - #{auction.id}"
  end

  def vessel_name_list(vessels) do
    vessels
    |> Enum.map(& &1.name)
    |> Enum.join(", ")
  end

  def supplier_name(%AuctionFixture{supplier: %Company{name: supplier_name}}) do
    supplier_name
  end

  def fuel_name(%AuctionFixture{fuel: %Fuel{name: fuel_name}}) do
    fuel_name
  end

  def vessel_name(%AuctionFixture{vessel: %Vessel{name: vessel_name}}) do
    vessel_name
  end
end
