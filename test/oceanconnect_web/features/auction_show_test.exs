defmodule Oceanconnect.AuctionShowTest do
  use Oceanconnect.FeatureCase
  alias Oceanconnect.{AuctionIndexPage, AuctionShowPage}
#  import Hound.Helpers.Session

  hound_session()

  setup do
    buyer_company = insert(:company)
    buyer = insert(:user, company: buyer_company)
    supplier_company = insert(:company, is_supplier: true)
    supplier = insert(:user, company: supplier_company)
    auction = insert(:auction, buyer: buyer_company, suppliers: [supplier_company])
    bid_params = %{
      amount: 1.25
    }
    Oceanconnect.Auctions.AuctionsSupervisor.start_child(auction)
    {:ok, %{auction: auction, bid_params: bid_params, buyer: buyer, supplier: supplier}}
  end

  describe "buyer login" do
    setup %{buyer: buyer} do
      login_user(buyer)
      :ok
    end

    test "auction start", %{auction: auction} do
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
  end

  describe "supplier login" do
    setup %{supplier: supplier} do
      login_user(supplier)
      :ok
    end

    test "supplier can see his view of the auction card", %{auction: auction} do
      AuctionShowPage.visit(auction.id)
      assert has_css?(".qa-auction-invitation-controls")
      refute has_css?(".qa-auction-suppliers")
    end

    test "supplier can enter a bid", %{auction: auction, bid_params: bid_params, supplier: supplier} do
      AuctionShowPage.visit(auction.id)
      AuctionShowPage.enter_bid(bid_params)
      AuctionShowPage.submit_bid()

      show_params = %{
        "lowest-bid-amount" => "$1.25",
        "lowest-bid-supplier" => supplier.company.name
      }
      assert AuctionShowPage.has_values_from_params?(show_params)
    end
  end
end
