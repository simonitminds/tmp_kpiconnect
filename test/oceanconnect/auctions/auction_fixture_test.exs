defmodule Oceanconnect.Auctions.AuctionFixtureTest do
  use Oceanconnect.DataCase
  alias Oceanconnect.Auctions
  alias Oceanconnect.Auctions.{AuctionFixture}

  setup do
    auction = insert(:auction, auction_vessel_fuels: [build(:vessel_fuel)])
    fixtures = insert_list(2, :auction_fixture, auction: auction)
    {:ok, %{auction: auction, fixtures: fixtures}}
  end

  test "fixtures_for_auction", %{auction: auction, fixtures: _fixtures} do
    assert fixtures = AuctionFixture.from_auction(auction) |> Repo.all
  end

  describe "create_fixtures_snapshot/1" do
    test "creating fixtures with out optional fields " do
      auction = insert(:auction, auction_vessel_fuels: [build(:vessel_fuel, etd: nil)])
      close_auction!(auction)
      :timer.sleep(200)
      new_state = Auctions.get_auction_state!(auction)

      assert {:ok, [%AuctionFixture{etd: nil}]} = Auctions.create_fixtures_from_state(new_state)
    end
  end
end
