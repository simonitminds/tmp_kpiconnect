defmodule Oceanconnect.Auctions.AuctionFixtureTest do
  use Oceanconnect.DataCase
  alias Oceanconnect.Auctions
  alias Oceanconnect.Auctions.{Auction, AuctionFixture, AuctionBid}

  setup do
    auction = insert(:auction, auction_vessel_fuels: [build(:vessel_fuel)])
    fixtures = insert_list(2, :auction_fixture, auction: auction)
    {:ok, %{auction: auction, fixtures: fixtures}}
  end

  test "fixtures_for_auction", %{auction: auction, fixtures: _fixtures} do
    assert fixtures = AuctionFixture.from_auction(auction) |> Repo.all
  end
end
