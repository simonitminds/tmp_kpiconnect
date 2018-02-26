defmodule Oceanconnect.AuctionShowTest do
  use Oceanconnect.FeatureCase, async: false
  alias Oceanconnect.{AuctionIndexPage, AuctionShowPage}
#  import Hound.Helpers.Session

  hound_session()

  setup do
    buyer_company = insert(:company)
    buyer = insert(:user, company: buyer_company)
    login_user(buyer)
    supplier_company = insert(:company, is_supplier: true)
    supplier = insert(:user, company: supplier_company)
    auction = insert(:auction, buyer: buyer_company, suppliers: [supplier_company])
    Oceanconnect.Auctions.AuctionsSupervisor.start_child(auction)
    {:ok, %{auction: auction, supplier: supplier}}
  end

   test "Auction start", %{auction: auction} do
     AuctionIndexPage.visit()
     AuctionIndexPage.start_auction(auction)
     AuctionShowPage.visit(auction.id)

     assert AuctionShowPage.is_current_path?(auction.id)
     assert AuctionShowPage.auction_status == "OPEN"
     assert AuctionShowPage.time_remaining() |> convert_to_millisecs < auction.duration
   end

  # TODO: Make this pass
   # test "Auction realtime start", %{auction: auction, supplier: supplier} do
   #   AuctionIndexPage.visit()

   #   in_browser_session(:supplier_session, fn ->
   #     login_user(supplier)
   #     AuctionShowPage.visit(auction.id)
   #     assert AuctionShowPage.is_current_path?(auction.id)
   #     assert AuctionShowPage.auction_status == "PENDING"
   #   end)

   #   AuctionIndexPage.start_auction(auction)

   #   in_browser_session :supplier_session, fn ->
   #     assert AuctionShowPage.is_current_path?(auction.id)
   #     assert AuctionShowPage.auction_status == "OPEN"
   #   end
   # end

   test "buyer can see his view of the auction card", %{auction: auction} do
     buyer_params = %{
       suppliers: auction.suppliers
     }

     AuctionShowPage.visit(auction.id)
     assert AuctionShowPage.has_values_from_params?(buyer_params)
   end

   test "supplier can see his view of the auction card", %{auction: auction, supplier: supplier} do
     login_user(supplier)
     AuctionShowPage.visit(auction.id)
     assert has_css?(".qa-auction-invitation-controls")
     refute has_css?(".qa-auction-suppliers")
   end
end
