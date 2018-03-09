defmodule Oceanconnect.AuctionShowTest do
  use Oceanconnect.FeatureCase
  alias Oceanconnect.{AuctionIndexPage, AuctionShowPage}
#  import Hound.Helpers.Session

  hound_session()

  setup do
    buyer_company = insert(:company)
    buyer = insert(:user, company: buyer_company)
    supplier_company = insert(:company, is_supplier: true)
    supplier_company2 = insert(:company, is_supplier: true)
    supplier = insert(:user, company: supplier_company)
    auction = insert(:auction, buyer: buyer_company, suppliers: [supplier_company, supplier_company2])
    bid_params = %{
      amount: 1.25
    }
    Oceanconnect.Auctions.AuctionsSupervisor.start_child(auction)
    {:ok, %{auction: auction, bid_params: bid_params, buyer: buyer, supplier: supplier,
            supplier_company: supplier_company, supplier_company2: supplier_company2}}
  end

  test "auction start", %{auction: auction, buyer: buyer} do
    login_user(buyer)
    AuctionIndexPage.visit()
    AuctionIndexPage.start_auction(auction)
    AuctionShowPage.visit(auction.id)

    assert AuctionShowPage.is_current_path?(auction.id)
    assert AuctionShowPage.auction_status == "OPEN"
    assert AuctionShowPage.time_remaining() |> convert_to_millisecs < auction.duration
  end

  describe "buyer login" do
    setup %{auction: auction, buyer: buyer} do
      login_user(buyer)
      AuctionIndexPage.visit()
      AuctionIndexPage.start_auction(auction)
      AuctionShowPage.visit(auction.id)
      :ok
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

     test "buyer can see the bid list", %{auction: auction} do
       [s1, s2] = auction.suppliers
       bid_list = [
         %{"amount" => 1.25, "supplier_id" => s1.id},
         %{"amount" => 1, "supplier_id" => s2.id}
       ]
       Enum.each(bid_list, fn(bid_params) ->
         create_bid_for_auction(bid_params, auction)
       end)
       stored_bid_list = AuctionBidList.get_bid_list(auction.id)
       bid_list_params = Enum.map(stored_bid_list, fn(bid) ->
         %{"bids" => %{
            "bid-#{bid.id}" => %{"amount" => bid.amount}
          }
       end)

       AuctionShowPage.visit(auction.id)
       assert AuctionShowPage.has_values_from_params?(buyer_params)
     end
  end

  describe "supplier login" do
    setup %{auction: auction, buyer: buyer, supplier: supplier} do
      login_user(buyer)
      AuctionIndexPage.visit()
      AuctionIndexPage.start_auction(auction)
      login_user(supplier)
      AuctionShowPage.visit(auction.id)
      :ok
    end

    test "supplier can see his view of the auction card" do
      assert has_css?(".qa-auction-invitation-controls")
      refute has_css?(".qa-auction-suppliers")
    end

    test "supplier can enter a bid", %{bid_params: bid_params, supplier: supplier} do
      AuctionShowPage.enter_bid(bid_params)
      AuctionShowPage.submit_bid()

      show_params = %{
        "winning-bid-amount" => "$1.25",
        "winning-bid-supplier" => "#{supplier.company.id}"
      }
      assert AuctionShowPage.has_values_from_params?(show_params)
    end
  end
end
