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
    auction = insert(:auction, buyer: buyer_company, suppliers: [supplier_company, supplier_company2], duration: 600_000)
    {:ok, _pid} = start_supervised({Oceanconnect.Auctions.AuctionSupervisor, auction})
    Auctions.start_auction(auction)
    bid = Auctions.place_bid(auction, %{"amount" => 1.25}, supplier_company.id, DateTime.utc_now(), supplier)
    Auctions.end_auction(auction)
    Auctions.select_winning_bid(bid, "test")
    :timer.sleep(500)
    login_user(buyer)
    AuctionLogPage.visit(auction.id)
    updated_auction = Auctions.Auction
    |> Oceanconnect.Repo.get(auction.id)
    |> Auctions.fully_loaded

    {:ok, %{auction: updated_auction, buyer_id: buyer_company.id, supplier: supplier}}
  end

  test "auction log has log details", %{auction: auction, supplier: supplier} do
    event_list = Auctions.AuctionEventStore.event_list(auction.id)
    assert AuctionLogPage.has_events?(event_list)
    assert AuctionLogPage.bid_has_supplier_as_user?(event_list, supplier)
    assert AuctionLogPage.event_user_displayed?(event_list)
  end

  test "page has auction details", %{auction: auction, buyer_id: buyer_id} do
    auction_payload = Auctions.AuctionPayload.get_auction_payload!(auction, buyer_id)

    expected_details = %{
      "created" => AuctionView.convert_date?(auction.inserted_at),
      "buyer-name" => auction.buyer.name,
      "auction_started" => AuctionView.convert_date?(auction.auction_start),
      "auction_ended" => AuctionView.convert_date?(auction.auction_ended),
      "actual-duration" => AuctionView.actual_duration(auction),
      "duration" => AuctionView.convert_duration(auction.duration),
      "winning-bid-amount" => "$#{auction_payload.state.winning_bid.amount}",
      "winning-supplier" => auction_payload.state.winning_bid.supplier,
    }
    assert AuctionLogPage.has_details?(expected_details)
  end
end
