defmodule Oceanconnect.TermAuctionShowTest do
  use Oceanconnect.FeatureCase
  alias Oceanconnect.{AuctionShowPage, AuctionNewPage}
  alias Oceanconnect.Auctions

  hound_session()

  setup do
    auction = insert(:term_auction)

    fuel = auction.fuel
    buyer_company = auction.buyer
    [supplier_company] = auction.suppliers

    buyer = insert(:user, company: buyer_company)
    supplier = insert(:user, company: supplier_company)

    bid_params = %{
      amount: 1.25,
      # comment: "Screw you!"
    }

    {:ok, _pid} =
      start_supervised(
        {Oceanconnect.Auctions.AuctionSupervisor,
         {auction, %{exclude_children: [:auction_reminder_timer]}}}
      )

    {:ok,
     %{
       auction: auction,
       buyer: buyer,
       buyer_company: buyer_company,
       supplier: supplier,
       bid_params: bid_params,
       fuel: fuel,
       fuel_id: "#{fuel.id}"
     }}
  end

  describe "supplier login" do
    setup %{auction: auction, supplier: supplier} do
      Auctions.start_auction(auction)
      login_user(supplier)
      AuctionShowPage.visit(auction.id)
      :ok
    end

    test "supplier can enter a bid", %{
      auction: auction,
      supplier: supplier,
      bid_params: bid_params,
      fuel_id: fuel_id
    } do
      AuctionShowPage.enter_bid(bid_params)
      AuctionShowPage.submit_bid()

      :timer.sleep(500)

      auction_state =
        auction
        |> Auctions.get_auction_state!()

      stored_bid_list =
        auction_state.product_bids[fuel_id].bids
        |> AuctionShowPage.convert_to_supplier_names(auction)

      bid_list_params =
        Enum.map(stored_bid_list, fn bid ->
          %{"id" => bid.id, "data" => %{"amount" => "$#{bid.amount}"}}
        end)

      assert AuctionShowPage.bid_list_has_bids?("supplier", bid_list_params)
      assert AuctionShowPage.has_bid_message?("Bids successfully placed")
    end
  end
end
