defmodule Oceanconnect.TermAuctionShowTest do
  use Oceanconnect.FeatureCase
  alias Oceanconnect.{AuctionShowPage}
  alias Oceanconnect.Auctions

  hound_session()

  setup do
    buyer_company = insert(:company, credit_margin_amount: 5.00)
    buyer = insert(:user, company: buyer_company)
    supplier_company = insert(:company, is_supplier: true)
    supplier_company2 = insert(:company, is_supplier: true)
    supplier_company3 = insert(:company, is_supplier: true)
    supplier = insert(:user, company: supplier_company)
    supplier2 = insert(:user, company: supplier_company2)
    supplier3 = insert(:user, company: supplier_company3)

    auction =
      insert(:term_auction,
        suppliers: [supplier_company, supplier_company2, supplier_company3]
      )
      |> Auctions.fully_loaded

    fuel = auction.fuel
    buyer_company = auction.buyer

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
       supplier2: supplier2,
       supplier3: supplier3,
       bid_params: bid_params,
       fuel: fuel,
       fuel_id: "#{fuel.id}"
     }}
  end

  describe "buyer login" do
    setup %{auction: auction, buyer: buyer} do
      Auctions.start_auction(auction)
      login_user(buyer)
      AuctionShowPage.visit(auction.id)
      :ok
    end

    test "buyer can see the bid list", %{auction: auction, fuel_id: fuel_id} do
      [s1, s2, _s3] = auction.suppliers

      create_bid(1.75, nil, s1.id, fuel_id, auction, true)
      |> Auctions.place_bid(insert(:user, company: s1))

      create_bid(1.75, nil, s2.id, fuel_id, auction, false)
      |> Auctions.place_bid(insert(:user, company: s2))

      auction_state =
        auction
        |> Auctions.get_auction_state!()

      stored_bid_list =
        auction_state.product_bids[fuel_id].bids
        |> AuctionShowPage.convert_to_supplier_names(auction)

      bid_list_expectations =
        Enum.map(stored_bid_list, fn bid ->
          is_traded_bid = if bid.is_traded_bid, do: "Traded Bid", else: ""

          %{
            "id" => bid.id,
            "data" => %{
              "amount" => "$#{bid.amount}",
              "supplier" => bid.supplier,
              "is_traded_bid" => is_traded_bid
            }
          }
        end)

      AuctionShowPage.visit(auction.id)
      assert AuctionShowPage.bid_list_has_bids?("buyer", bid_list_expectations)
    end
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
