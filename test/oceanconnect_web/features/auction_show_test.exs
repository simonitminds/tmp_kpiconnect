defmodule Oceanconnect.AuctionShowTest do
  use Oceanconnect.FeatureCase
  alias Oceanconnect.{AuctionIndexPage, AuctionShowPage}
#  import Hound.Helpers.Session

  hound_session()

  setup do
    buyer = insert(:user)
    supplier = insert(:user)
    auction = insert(:auction, buyer: buyer)
    Oceanconnect.Auctions.AuctionsSupervisor.start_child(auction.id)
    login_user(buyer)
    {:ok, %{auction: auction, supplier: supplier}}
  end

   test "Auction start", %{auction: auction} do
     AuctionIndexPage.visit()
     AuctionIndexPage.start_auction(auction)
     AuctionShowPage.visit(auction.id)

     assert AuctionShowPage.is_current_path?(auction.id)
     assert AuctionShowPage.auction_status == "OPEN"
   end

  # TODO: Make this pass
   test "Auction realtime start", %{auction: auction, supplier: supplier} do
     AuctionIndexPage.visit()

     in_browser_session(:supplier_session, fn ->
       login_user(supplier)
       AuctionShowPage.visit(auction.id)
       assert AuctionShowPage.is_current_path?(auction.id)
       assert AuctionShowPage.auction_status == "PENDING"
     end)

     AuctionIndexPage.start_auction(auction)

     in_browser_session :supplier_session, fn ->
       assert AuctionShowPage.is_current_path?(auction.id)
       assert AuctionShowPage.auction_status == "OPEN"
     end
   end
end
