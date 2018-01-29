defmodule Oceanconnect.AuctionIndexTest do
  use Oceanconnect.FeatureCase
  alias Oceanconnect.AuctionIndexPage

  hound_session()

  setup do
    user = insert(:user)
    login_user(user)
    supplier = insert(:user)
    auctions = insert_list(2, :auction, suppliers: [supplier])
    {:ok, %{auctions: auctions, supplier: supplier}}
  end

  test "renders the default auction index page", %{auctions: auctions} do
    AuctionIndexPage.visit()
    assert AuctionIndexPage.is_current_path?()
    assert AuctionIndexPage.has_auctions?(auctions)
  end

  test "Auction realtime start", %{auctions: auctions, supplier: supplier} do
    auction = hd(auctions)
    Oceanconnect.Auctions.AuctionsSupervisor.start_child(auction.id)
    AuctionIndexPage.visit()

    in_browser_session("supplier_session", fn ->
      login_user(supplier)
      AuctionIndexPage.visit()
      assert AuctionIndexPage.is_current_path?
      assert AuctionIndexPage.auction_status(auction) == "PENDING"
    end)

    AuctionIndexPage.start_auction(auction)

    in_browser_session "supplier_session", fn ->
      assert AuctionIndexPage.is_current_path?()
      assert AuctionIndexPage.auction_status(auction) == "OPEN"
    end
  end
end
