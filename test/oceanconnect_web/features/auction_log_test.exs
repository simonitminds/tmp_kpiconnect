defmodule Oceanconnect.AuctionLogTest do
  use Oceanconnect.FeatureCase
  alias Oceanconnect.AuctionLogPage
  alias Oceanconnect.Auctions
  alias OceanconnectWeb.AuctionView

  hound_session()

  setup do
    buyer_company = insert(:company)
    buyer = insert(:user, company: buyer_company)
    supplier_company = insert(:company, is_supplier: true)
    supplier_company2 = insert(:company, is_supplier: true)
    supplier = insert(:user, company: supplier_company)
    insert(:company, name: "Ocean Connect Marine")

    fuel = insert(:fuel)
    fuel_id = "#{fuel.id}"

    auction =
      insert(
        :auction,
        buyer: buyer_company,
        suppliers: [supplier_company, supplier_company2],
        auction_vessel_fuels: [build(:vessel_fuel, fuel: fuel)],
        duration: 600_000
      ) |> Auctions.fully_loaded()

    {:ok, _pid} =
      start_supervised(
        {Oceanconnect.Auctions.AuctionSupervisor,
         {auction, %{exclude_children: [:auction_reminder_timer, :auction_scheduler]}}}
      )

    Auctions.start_auction(auction)

    bid = create_bid(1.25, nil, supplier_company.id, fuel_id, auction)
    |> Auctions.place_bid(supplier)

    Auctions.end_auction(auction)

    state = Auctions.get_auction_state!(auction)
    Auctions.select_winning_solution([bid], state.product_bids, auction, "test", "Agent 9")

    :timer.sleep(500)
    login_user(buyer)
    AuctionLogPage.visit(auction.id)

    updated_auction =
      Auctions.Auction
      |> Oceanconnect.Repo.get(auction.id)
      |> Auctions.fully_loaded()

    auction_events = Auctions.AuctionEventStore.event_list(updated_auction.id)

    {:ok, %{auction: updated_auction, buyer_id: buyer_company.id, supplier: supplier, fuel: fuel, auction_events: auction_events}}
  end

  test "auction log has log details", %{auction_events: auction_events} do
    assert AuctionLogPage.has_events?(auction_events)
  end

  test "page has auction details", %{auction: auction, fuel: fuel, supplier: supplier, auction_events: auction_events} do
    expected_details = %{
      "created" => AuctionView.convert_date?(auction.inserted_at),
      "buyer-name" => auction.buyer.name,
      "auction_started" => AuctionView.convert_date?(auction.scheduled_start),
      "auction_ended" => AuctionView.convert_date?(auction.auction_ended),
      "actual-duration" => AuctionView.actual_duration(auction_events),
      "duration" => AuctionView.convert_duration(auction.duration),
      "winning-solution-entry" => "$1.25/unit for #{fuel.name} from #{supplier.company.name}"
    }

    assert AuctionLogPage.has_details?(expected_details)
  end

  test "auction log displays all vessel_fuels", %{auction: auction} do
    vessel_fuels = auction.auction_vessel_fuels
    Enum.all?(vessel_fuels, fn(vessel_fuel) ->
      assert AuctionLogPage.has_vessel_fuel?(vessel_fuel)
    end)
  end
end
