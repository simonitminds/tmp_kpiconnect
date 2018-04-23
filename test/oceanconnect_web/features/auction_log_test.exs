defmodule Oceanconnect.AuctionLogTest do
  use Oceanconnect.FeatureCase
  alias Oceanconnect.AuctionLogPage
  alias Oceanconnect.Auctions

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
    bid = Auctions.place_bid(auction, %{"amount" => 1.25}, supplier_company.id)
    Auctions.end_auction(auction)
    Auctions.select_winning_bid(bid, "test")

    {:ok, %{auction: auction, buyer: buyer, supplier: supplier}}
  end

  test "auction log has log details", %{auction: auction, buyer: buyer} do
    login_user(buyer)
    AuctionLogPage.visit(auction.id)

    expected_events = [
      "auction_closed",
      "winning_bid_selected",
      "auction_ended",
      "bid_placed",
      "auction_updated",
      "auction_started"
    ]
    assert AuctionLogPage.has_event_types?(expected_events)
  end

end
