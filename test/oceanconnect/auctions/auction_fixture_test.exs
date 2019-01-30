defmodule Oceanconnect.Auctions.AuctionFixtureTest do
  use Oceanconnect.DataCase
#  alias Oceanconnect.Auctions
#  alias Oceanconnect.Auctions.{Auction, AuctionFixture}
  alias Oceanconnect.Auctions.AuctionFixture
  setup do
    auction = insert(:auction)
    fixtures = insert_list(2, :auction_fixture, auction: auction)
    # factory up an auction
    # close it
    # Fixtures should get generated
    {:ok, %{auction: auction, fixtures: fixtures}}
  end

  test "fixtures_for_auction", %{auction: auction, fixtures: _fixtures} do
    assert fixtures = AuctionFixture.from_auction(auction) |> Repo.all
  end
end
