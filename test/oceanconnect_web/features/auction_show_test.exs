defmodule Oceanconnect.AuctionShowTest do
  use Oceanconnect.FeatureCase, async: true
  alias Oceanconnect.{AuctionIndexPage, AuctionShowPage}
  import Hound.Helpers.Session

  hound_session()

  setup do
    buyer = insert(:user)
    supplier = insert(:user)
    auction = insert(:auction, buyer: buyer)
    login_user(buyer)
    {:ok, %{auction: auction, supplier: supplier}}
  end

  test "Auction start", %{auction: auction, supplier: supplier} do
    AuctionIndexPage.visit()

    in_browser_session(:supplier_session, fn ->
      login_user(supplier)
      AuctionShowPage.visit(auction.id)
      assert AuctionShowPage.auction_status == "Pending"
    end)

    AuctionIndexPage.start_auction(auction)

    in_browser_session :supplier_session, fn ->
      assert AuctionShowPage.is_current_path()
      assert AuctionShowPage.auction_status == "Open"
    end
  end
end
