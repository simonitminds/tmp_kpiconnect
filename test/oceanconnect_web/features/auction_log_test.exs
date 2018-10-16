defmodule Oceanconnect.AuctionLogTest do
  use Oceanconnect.FeatureCase
  alias Oceanconnect.AuctionLogPage
  alias Oceanconnect.Auctions
  alias Oceanconnect.Auctions.Payloads.SolutionsPayload
  alias OceanconnectWeb.AuctionView

  hound_session()

  setup do
    buyer_company = insert(:company)
    buyer = insert(:user, company: buyer_company)
    supplier_company = insert(:company, is_supplier: true)
    supplier_company2 = insert(:company, is_supplier: true)
    supplier = insert(:user, company: supplier_company)

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
    Auctions.select_winning_solution([bid], state.product_bids, auction, "test")

    :timer.sleep(500)
    login_user(buyer)
    AuctionLogPage.visit(auction.id)

    updated_auction =
      Auctions.Auction
      |> Oceanconnect.Repo.get(auction.id)
      |> Auctions.fully_loaded()

    {:ok, %{auction: updated_auction, buyer_id: buyer_company.id, supplier: supplier}}
  end

  test "auction log has log details", %{auction: auction, supplier: supplier} do
    event_list = Auctions.AuctionEventStore.event_list(auction.id)
    assert AuctionLogPage.has_events?(event_list)
    assert AuctionLogPage.bid_has_supplier_as_user?(event_list, supplier)
    assert AuctionLogPage.event_user_displayed?(event_list)
  end

  test "page has auction details", %{auction: auction, buyer_id: buyer_id} do
    solutions_payload = Auctions.get_auction_state!(auction)
    |> SolutionsPayload.get_solutions_payload!([auction: auction, buyer: buyer_id])

    expected_details = %{
      "created" => AuctionView.convert_date?(auction.inserted_at),
      "buyer-name" => auction.buyer.name,
      "auction_started" => AuctionView.convert_date?(auction.scheduled_start),
      "auction_ended" => AuctionView.convert_date?(auction.auction_ended),
      "actual-duration" => AuctionView.actual_duration(auction),
      "duration" => AuctionView.convert_duration(auction.duration),
      "winning-solution-normalized-price" => "$#{solutions_payload.winning_solution.normalized_price}",
      "winning-suppliers" => AuctionView.auction_log_suppliers(solutions_payload)
    }

    assert AuctionLogPage.has_details?(expected_details)
  end

  test "auction log displays all vessel_fuels", %{auction: auction, buyer_id: buyer_id} do
    vessel_fuels = auction.auction_vessel_fuels
    Enum.all?(vessel_fuels, fn(vessel_fuel) ->
      assert AuctionLogPage.has_vessel_fuel?(vessel_fuel)
    end)
  end
end
