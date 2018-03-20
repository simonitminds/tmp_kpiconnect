defmodule Oceanconnect.AuctionShowTest do
  use Oceanconnect.FeatureCase
  alias Oceanconnect.{AuctionIndexPage, AuctionShowPage}
  alias Oceanconnect.Auctions
#  import Hound.Helpers.Session

  hound_session()

  setup do
    buyer_company = insert(:company)
    buyer = insert(:user, company: buyer_company)
    supplier_company = insert(:company, is_supplier: true)
    supplier_company2 = insert(:company, is_supplier: true)
    supplier = insert(:user, company: supplier_company)
    supplier2 = insert(:user, company: supplier_company2)
    auction = insert(:auction, buyer: buyer_company, suppliers: [supplier_company, supplier_company2])
    bid_params = %{
      amount: 1.25
    }
    Oceanconnect.Auctions.AuctionsSupervisor.start_child(auction)
    Oceanconnect.Auctions.AuctionBidsSupervisor.start_child(auction.id)
    {:ok, %{auction: auction, bid_params: bid_params, buyer: buyer, supplier: supplier,
            supplier_company: supplier_company, supplier2: supplier2, supplier_company2: supplier_company2}}
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

  test "Auction realtime start", %{auction: auction, supplier: supplier, buyer: buyer} do
    login_user(buyer)
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


  describe "buyer login" do
    setup %{auction: auction, buyer: buyer} do
      login_user(buyer)
      AuctionIndexPage.visit()
      AuctionIndexPage.start_auction(auction)
      AuctionShowPage.visit(auction.id)
      :ok
    end

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
        %{"amount" => 1.75, "supplier_id" => s1.id},
        %{"amount" => 1.25, "supplier_id" => s2.id}
      ]
      Enum.each(bid_list, fn(bid_params) ->
        create_bid_for_auction(bid_params, auction)
      end)
      stored_bid_list = auction.id
      |> Auctions.AuctionBidList.get_bid_list
      |> Auctions.convert_to_supplier_names(auction)
      bid_list_params = Enum.map(stored_bid_list, fn(bid) ->
        %{"id" => bid.id,
          "data" => %{"amount" => "$#{bid.amount}", "supplier" => bid.supplier}}
      end)

      auction
      |> Auctions.get_auction_state
      |> Auctions.build_auction_state_payload(auction.buyer_id)

      AuctionShowPage.visit(auction.id)
      assert AuctionShowPage.has_bid_list_bids?(bid_list_params)
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

    test "supplier can enter a bid", %{auction: auction, bid_params: bid_params, supplier_company: supplier_company} do
      AuctionShowPage.enter_bid(bid_params)
      AuctionShowPage.submit_bid()

      stored_bid_list = auction.id
      |> Auctions.AuctionBidList.get_bid_list
      |> Auctions.supplier_bid_list(supplier_company.id)
      bid_list_params = Enum.map(stored_bid_list, fn(bid) ->
        %{"id" => bid.id,
          "data" => %{"amount" => "$#{bid.amount}"}}
      end)
      assert AuctionShowPage.has_values_from_params?(%{"winning-bid-amount" => "$1.25"})
      assert AuctionShowPage.has_bid_list_bids?(bid_list_params)
    end

    test "index displays bid status to suppliers", %{supplier2: supplier2, auction: auction} do
      assert AuctionShowPage.auction_bid_status() =~ "You have not bid on this auction"
      AuctionShowPage.enter_bid(%{amount: 1.00})
      AuctionShowPage.submit_bid()
      :timer.sleep(500)
      assert AuctionShowPage.auction_bid_status() =~ "Your bid is currently lowest"

      in_browser_session(:second_supplier, fn ->
        login_user(supplier2)
        AuctionShowPage.visit(auction.id)
        assert AuctionShowPage.auction_bid_status() =~ "You have not bid on this auction"
        AuctionShowPage.enter_bid(%{amount: 0.50})
        AuctionShowPage.submit_bid()
        :timer.sleep(500)
        assert AuctionShowPage.auction_bid_status() =~ "Your bid is currently lowest"
      end)

      # TODO: Get chrome to run incognito to isolate sessions for this to pass
      # change_session_to(:default)
      # assert AuctionShowPage.auction_bid_status() =~ "You have been outbid"
      # AuctionShowPage.enter_bid(%{amount: 0.50})
      # AuctionShowPage.submit_bid()
      # assert AuctionShowPage.auction_bid_status() =~ "You are in lowest bid position number 2"
    end
  end
end
