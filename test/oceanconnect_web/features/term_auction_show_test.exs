defmodule Oceanconnect.TermAuctionShowTest do
  use Oceanconnect.FeatureCase
  alias Oceanconnect.{AuctionShowPage, AuctionNewPage}
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
        buyer: buyer_company,
        suppliers: [supplier_company, supplier_company2, supplier_company3],
        is_traded_bid_allowed: true
      )
      |> Auctions.fully_loaded()

    fuel = auction.fuel

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

  test "auction start", %{auction: auction, buyer: buyer} do
    Auctions.start_auction(auction)

    login_user(buyer)
    AuctionShowPage.visit(auction.id)

    assert AuctionShowPage.is_current_path?(auction.id)
    assert AuctionShowPage.auction_status() == "OPEN"
    assert AuctionShowPage.time_remaining() |> convert_to_millisecs < auction.duration
  end

  test "Auction realtime start", %{auction: auction, supplier: supplier} do
    login_user(supplier)
    AuctionShowPage.visit(auction.id)
    assert AuctionShowPage.is_current_path?(auction.id)
    assert AuctionShowPage.auction_status() == "PENDING"

    Auctions.start_auction(auction)
    :timer.sleep(300)

    assert AuctionShowPage.is_current_path?(auction.id)
    assert AuctionShowPage.auction_status() == "OPEN"
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

    test "buyer selects solution", %{
      auction: auction,
      fuel_id: fuel_id
    } do
      supplier = hd(auction.suppliers)

      bid =
        create_bid(1.75, nil, supplier.id, fuel_id, auction, true)
        |> Auctions.place_bid(insert(:user, company: supplier))

      AuctionShowPage.visit(auction.id)
      AuctionShowPage.select_solution(0)
      :timer.sleep(500)
      AuctionShowPage.accept_bid()
      :timer.sleep(500)

      assert AuctionShowPage.auction_status() == "CLOSED"
      assert AuctionShowPage.winning_solution_has_bids?([bid])
    end

    test "buyer selects solution with comment and port agent", %{
      auction: auction,
      fuel_id: fuel_id
    } do
      supplier = hd(auction.suppliers)

      bid =
        create_bid(1.75, nil, supplier.id, fuel_id, auction, true)
        |> Auctions.place_bid(insert(:user, company: supplier))

      AuctionShowPage.visit(auction.id)
      AuctionShowPage.select_solution(0)
      :timer.sleep(100)
      AuctionShowPage.enter_solution_comment("Screw you!")
      AuctionShowPage.enter_port_agent("Test Agent")
      AuctionShowPage.accept_bid()
      :timer.sleep(500)

      assert AuctionShowPage.auction_status() == "CLOSED"
      assert AuctionShowPage.winning_solution_has_bids?([bid])
    end

    test "buyer can see supplier's comments on ranked offers", %{auction: auction, supplier: supplier} do
      in_browser_session(:supplier, fn ->
        login_user(supplier)
        AuctionShowPage.visit(auction.id)
        :timer.sleep(100)
        AuctionShowPage.enter_bid(%{amount: 9.50})
        AuctionShowPage.submit_bid()
        :timer.sleep(100)

        AuctionShowPage.enter_comment("Hi")
        AuctionShowPage.submit_comment()

        assert AuctionShowPage.has_content?("Hi")
      end)
      AuctionShowPage.visit(auction.id)
      :timer.sleep(100)
      AuctionShowPage.select_solution(0)
      :timer.sleep(100)
      assert AuctionShowPage.has_content?("Hi")
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

    test "supplier can enter a traded bid", %{
      auction: auction,
      bid_params: bid_params,
      buyer_company: buyer_company,
      fuel_id: fuel_id
    } do
      AuctionShowPage.enter_bid(bid_params)
      AuctionShowPage.mark_as_traded_bid()

      assert AuctionNewPage.credit_margin_amount() ==
               :erlang.float_to_binary(buyer_company.credit_margin_amount, decimals: 2)

      AuctionShowPage.submit_bid()

      :timer.sleep(500)

      auction_state =
        auction
        |> Auctions.get_auction_state!()

      stored_bid_list =
        auction_state.product_bids[fuel_id].bids
        |> AuctionShowPage.convert_to_supplier_names(auction)

      bid_list_card_expectations =
        Enum.map(stored_bid_list, fn bid ->
          is_traded_bid = if bid.is_traded_bid, do: "Traded Bid", else: ""

          %{
            "id" => bid.id,
            "data" => %{"amount" => "$#{bid.amount}", "is_traded_bid" => is_traded_bid}
          }
        end)

      assert AuctionShowPage.bid_list_has_bids?("supplier", bid_list_card_expectations)
      assert AuctionShowPage.has_bid_message?("Bids successfully placed")
    end

    test "supplier places minimum bid and maintains winning position", %{
      supplier2: supplier2,
      auction: auction
    } do
      AuctionShowPage.enter_bid(%{amount: 10.00, min_amount: 9.00})
      AuctionShowPage.submit_bid()
      :timer.sleep(500)

      assert AuctionShowPage.auction_bid_status() =~
               "You have the best overall offer for this auction"

      in_browser_session(:second_supplier, fn ->
        login_user(supplier2)
        AuctionShowPage.visit(auction.id)
        :timer.sleep(500)
        AuctionShowPage.enter_bid(%{amount: 9.50})
        AuctionShowPage.submit_bid()
        :timer.sleep(500)
        assert AuctionShowPage.auction_bid_status() =~ "Your bid is not the best offer"
      end)

      change_session_to(:default)

      assert AuctionShowPage.auction_bid_status() =~
               "You have the best overall offer for this auction"

      AuctionShowPage.visit(auction.id)

      assert AuctionShowPage.auction_bid_status() =~
               "You have the best overall offer for this auction"
    end

    test "supplier can revoke their bid for a product", %{
      auction: auction,
      fuel_id: fuel_id
    } do
      AuctionShowPage.enter_bid(%{amount: 10.00, min_amount: 9.00})
      AuctionShowPage.submit_bid()
      :timer.sleep(700)

      assert AuctionShowPage.auction_bid_status() =~
               "You have the best overall offer for this auction"

      AuctionShowPage.revoke_bid_for_product(fuel_id)
      :timer.sleep(500)
      assert AuctionShowPage.auction_bid_status() =~ "You have not bid on this auction"

      auction_state =
        auction
        |> Auctions.get_auction_state!()

      stored_bid_list = auction_state.product_bids[fuel_id].bids

      bid_list_card_expectations =
        Enum.map(stored_bid_list, fn bid ->
          %{
            "id" => bid.id,
            "data" => %{
              "amount" => "$#{bid.amount}"
            }
          }
        end)

      assert AuctionShowPage.bid_list_has_bids?("supplier", bid_list_card_expectations)
    end

    test "supplier can add comments to offers" do
      AuctionShowPage.enter_bid(%{amount: 10.00, min_amount: 9.00})
      AuctionShowPage.submit_bid()
      :timer.sleep(100)

      assert AuctionShowPage.auction_bid_status() =~ "You have the best overall offer for this auction"

      AuctionShowPage.enter_comment("You have to buy this!")
      AuctionShowPage.submit_comment()
      :timer.sleep(100)
      assert AuctionShowPage.has_content?("You have to buy this!")
    end

    test "supplier can delete their comments" do
      AuctionShowPage.enter_bid(%{amount: 10.00, min_amount: 9.00})
      AuctionShowPage.submit_bid()
      :timer.sleep(100)

      assert AuctionShowPage.auction_bid_status() =~ "You have the best overall offer for this auction"

      AuctionShowPage.enter_comment("You have to buy this!")
      AuctionShowPage.submit_comment()
      :timer.sleep(100)
      assert AuctionShowPage.has_content?("You have to buy this!")

      AuctionShowPage.delete_comment(0)
      :timer.sleep(100)
      refute AuctionShowPage.has_content?("You have to buy this!")
    end
  end


  describe "barges" do
    test "supplier cannot submit a barge for approval once an auction has expired", %{
      auction: auction,
      supplier: supplier
    } do
      barge = insert(:barge, companies: [supplier.company], imo_number: "1234567")

      inactive_barge =
        insert(:barge, companies: [supplier.company], imo_number: "1234568", is_active: false)

      Auctions.start_auction(auction)
      login_user(supplier)
      AuctionShowPage.visit(auction.id)
      Auctions.end_auction(auction)
      Auctions.expire_auction(auction)
      :timer.sleep(500)
      assert AuctionShowPage.auction_status() == "EXPIRED"

      assert AuctionShowPage.has_available_barge?(barge)
      refute AuctionShowPage.has_available_barge?(inactive_barge)

      assert_raise Hound.NoSuchElementError, fn ->
        AuctionShowPage.submit_barge(barge)
      end

      assert_raise Hound.NoSuchElementError, fn ->
        AuctionShowPage.has_submitted_barge?(barge)
      end
    end

    test "supplier views a list of their barges", %{
      auction: auction,
      supplier: supplier
    } do
      barge = insert(:barge, companies: [supplier.company], imo_number: "1234567")
      login_user(supplier)
      AuctionShowPage.visit(auction.id)
      assert AuctionShowPage.has_available_barge?(barge)
    end

    test "supplier can submit barge for approval", %{
      auction: auction,
      supplier: supplier
    } do
      barge = insert(:barge, companies: [supplier.company], imo_number: "1234567")

      inactive_barge =
        insert(:barge, companies: [supplier.company], imo_number: "1234568", is_active: false)

      login_user(supplier)
      AuctionShowPage.visit(auction.id)
      :timer.sleep(500)
      assert AuctionShowPage.has_available_barge?(barge)
      refute AuctionShowPage.has_available_barge?(inactive_barge)

      AuctionShowPage.submit_barge(barge)
      :timer.sleep(500)
      assert AuctionShowPage.has_submitted_barge?(barge)
    end

    test "supplier can unsubmit barge from approval", %{
      auction: auction,
      supplier: supplier
    } do
      barge = insert(:barge, companies: [supplier.company], imo_number: "1234567")
      login_user(supplier)
      AuctionShowPage.visit(auction.id)
      :timer.sleep(400)
      assert AuctionShowPage.has_available_barge?(barge)

      AuctionShowPage.submit_barge(barge)
      :timer.sleep(400)
      AuctionShowPage.unsubmit_barge(barge)
      :timer.sleep(400)
      assert AuctionShowPage.has_no_submitted_barges?()
      assert AuctionShowPage.has_available_barge?(barge)
    end

    test "buyer can approve submitted barges", %{
      auction: auction,
      buyer: buyer,
      supplier: supplier,
      supplier2: supplier2
    } do
      barge =
        insert(:barge, companies: [supplier.company, supplier2.company], imo_number: "1234567")

      Auctions.submit_barge(auction, barge, supplier.company_id)
      Auctions.submit_barge(auction, barge, supplier2.company_id)

      login_user(buyer)
      AuctionShowPage.visit(auction.id)
      :timer.sleep(500)

      AuctionShowPage.approve_barge(barge, supplier.company_id)
      :timer.sleep(400)

      AuctionShowPage.expand_supplier_barges(supplier.company_id)
      assert AuctionShowPage.has_approved_barge?(barge, supplier.company_id)
      assert AuctionShowPage.has_pending_barge?(barge, supplier2.company_id)
    end

    test "buyer can reject submitted barges", %{
      auction: auction,
      buyer: buyer,
      supplier: supplier,
      supplier2: supplier2
    } do
      barge =
        insert(:barge, companies: [supplier.company, supplier2.company], imo_number: "1234567")

      Auctions.submit_barge(auction, barge, supplier.company_id)
      Auctions.submit_barge(auction, barge, supplier2.company_id)

      login_user(buyer)
      AuctionShowPage.visit(auction.id)
      :timer.sleep(400)

      AuctionShowPage.reject_barge(barge, supplier.company_id)
      :timer.sleep(400)

      AuctionShowPage.expand_supplier_barges(supplier.company_id)
      assert AuctionShowPage.has_rejected_barge?(barge, supplier.company_id)
      assert AuctionShowPage.has_pending_barge?(barge, supplier2.company_id)
    end
  end
end
