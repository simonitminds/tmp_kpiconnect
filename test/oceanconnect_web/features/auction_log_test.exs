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

    vessel_fuel = insert(:vessel_fuel)
    vessel_fuel_id = "#{vessel_fuel.id}"

    auction =
      insert(
        :auction,
        buyer: buyer_company,
        suppliers: [supplier_company, supplier_company2],
        auction_vessel_fuels: [vessel_fuel],
        duration: 600_000
      )
      |> Auctions.fully_loaded()

    message =
      insert(:message,
        auction: auction,
        author_company: supplier_company2,
        recipient_company: buyer_company
      )

    messages =
      insert_list(2, :message,
        auction: auction,
        author_company: buyer_company,
        recipient_company: supplier_company
      )

    {:ok, _pid} =
      start_supervised(
        {Oceanconnect.Auctions.AuctionSupervisor,
         {auction, %{exclude_children: [:auction_reminder_timer, :auction_scheduler]}}}
      )

    Auctions.start_auction(auction)

    bid =
      create_bid(1.25, nil, supplier_company.id, vessel_fuel_id, auction)
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

    {:ok,
     %{
       auction: updated_auction,
       buyer_id: buyer_company.id,
       supplier: supplier,
       vessel_fuel: vessel_fuel,
       auction_events: auction_events,
       messages: [message | messages]
     }}
  end

  test "auction log has log details", %{auction_events: auction_events} do
    assert AuctionLogPage.has_events?(auction_events)
  end

  test "page has auction details", %{
    auction: auction,
    vessel_fuel: vessel_fuel,
    supplier: supplier,
    auction_events: auction_events
  } do
    expected_details = %{
      "created" => AuctionView.convert_date?(auction.inserted_at),
      "buyer-name" => auction.buyer.name,
      "auction_started" => AuctionView.convert_date?(auction.auction_started),
      "auction_ended" => AuctionView.convert_date?(auction.auction_ended),
      "actual-duration" => AuctionView.actual_duration(auction),
      "duration" => AuctionView.convert_duration(auction.duration),
      "winning-solution-entry" =>
        "$1.25/unit for #{vessel_fuel.fuel.name} from #{supplier.company.name} to #{
          vessel_fuel.vessel.name
        }"
    }

    assert AuctionLogPage.has_details?(expected_details)
  end

  test "auction log displays all vessel_fuels", %{auction: auction} do
    vessel_fuels = auction.auction_vessel_fuels

    Enum.all?(vessel_fuels, fn vessel_fuel ->
      assert AuctionLogPage.has_vessel_fuel?(vessel_fuel)
    end)
  end

  test "page has message details", %{messages: [message | _]} do
    expected_details = %{
      "time" => AuctionView.convert_date_time?(message.inserted_at),
      "content" => message.content,
      "author" => AuctionView.author_name_and_company(message)
    }

    assert AuctionLogPage.has_message_details?(message.id, expected_details)
  end
end
