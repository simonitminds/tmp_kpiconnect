defmodule Oceanconnect.AuctionShowTest do
  use Oceanconnect.FeatureCase
  alias Oceanconnect.{AuctionShowPage, AuctionNewPage}
  alias Oceanconnect.Auctions
  #  import Hound.Helpers.Session

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
    insert(:company, name: "Ocean Connect Marine")

    fuel = insert(:fuel)
    fuel_id = "#{fuel.id}"

    auction =
      insert(
        :auction,
        buyer: buyer_company,
        suppliers: [supplier_company, supplier_company2, supplier_company3],
        auction_vessel_fuels: [build(:vessel_fuel, fuel: fuel)],
        is_traded_bid_allowed: true
      )
      |> Auctions.fully_loaded()

    bid_params = %{
      amount: 1.25
    }

    {:ok, _pid} =
      start_supervised(
        {Oceanconnect.Auctions.AuctionSupervisor,
         {auction, %{exclude_children: [:auction_reminder_timer]}}}
      )

    {:ok,
     %{
       auction: auction,
       bid_params: bid_params,
       buyer: buyer,
       supplier: supplier,
       supplier2: supplier2,
       supplier3: supplier3,
       buyer_company: buyer_company,
       fuel_id: fuel_id,
       fuel: fuel
     }}
  end

  test "channel disconnected status is detected/displayed", %{auction: auction, buyer: buyer} do
    login_user(buyer)
    AuctionShowPage.visit(auction.id)
    assert AuctionShowPage.has_css?(".qa-channel-connected")

    # Disconnect user channel
    OceanconnectWeb.Endpoint.broadcast("user_socket:#{buyer.id}", "disconnect", %{})

    assert AuctionShowPage.has_css?(".qa-channel-disconnected")
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

    test "buyer can see his view of the auction card", %{auction: auction} do
      buyer_params = %{
        suppliers: auction.suppliers
      }

      AuctionShowPage.visit(auction.id)
      assert AuctionShowPage.has_values_from_params?(buyer_params)
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

      bid_list_card_expectations =
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
      assert AuctionShowPage.bid_list_has_bids?("buyer", bid_list_card_expectations)
    end
  end

  describe "supplier login" do
    setup %{auction: auction, supplier: supplier} do
      Auctions.start_auction(auction)
      login_user(supplier)
      AuctionShowPage.visit(auction.id)
      :timer.sleep(200)
      :ok
    end

    test "supplier can view the supplier auction card" do
      assert has_css?(".qa-supplier-bid-history")
      refute has_css?(".qa-auction-suppliers")
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

    test "index displays bid status to suppliers", %{
      supplier2: supplier2,
      auction: auction,
      fuel: fuel
    } do
      assert AuctionShowPage.auction_bid_status() =~ "You have not bid on this auction"
      AuctionShowPage.enter_bid(%{amount: 1.00})
      AuctionShowPage.submit_bid()
      :timer.sleep(500)

      assert AuctionShowPage.auction_bid_status() =~
               "Your bid is the best overall offer for #{fuel.name}"

      in_browser_session(:second_supplier, fn ->
        login_user(supplier2)
        AuctionShowPage.visit(auction.id)
        assert AuctionShowPage.auction_bid_status() =~ "You have not bid on this auction"
        AuctionShowPage.enter_bid(%{amount: 0.50})
        AuctionShowPage.submit_bid()
        :timer.sleep(500)

        assert AuctionShowPage.auction_bid_status() =~
                 "Your bid is the best overall offer for #{fuel.name}"
      end)

      change_session_to(:default)
      assert AuctionShowPage.auction_bid_status() =~ "Your bid is not the best offer"
      AuctionShowPage.visit(auction.id)
      AuctionShowPage.enter_bid(%{amount: 0.50})
      AuctionShowPage.submit_bid()
      :timer.sleep(500)

      assert AuctionShowPage.auction_bid_status() =~
               "Your bid matches the best single-supplier offer, but was not the first"
    end

    test "supplier places minimum bid and maintains winning position", %{
      supplier2: supplier2,
      auction: auction,
      fuel: fuel
    } do
      AuctionShowPage.enter_bid(%{amount: 10.00, min_amount: 9.00})
      AuctionShowPage.submit_bid()
      :timer.sleep(500)

      assert AuctionShowPage.auction_bid_status() =~
               "Your bid is the best overall offer for #{fuel.name}"

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
               "Your bid is the best overall offer for #{fuel.name}"

      AuctionShowPage.visit(auction.id)

      assert AuctionShowPage.auction_bid_status() =~
               "Your bid is the best overall offer for #{fuel.name}"
    end

    test "supplier can revoke their bid for a product", %{
      auction: auction,
      fuel_id: fuel_id,
      fuel: fuel
    } do
      AuctionShowPage.enter_bid(%{amount: 10.00, min_amount: 9.00})
      AuctionShowPage.submit_bid()
      :timer.sleep(500)

      assert AuctionShowPage.auction_bid_status() =~
               "Your bid is the best overall offer for #{fuel.name}"

      AuctionShowPage.revoke_bid_for_product(fuel_id)
      :timer.sleep(200)
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
  end

  describe "decision period" do
    setup %{auction: auction, supplier: supplier, supplier2: supplier2, fuel_id: fuel_id} do
      Auctions.start_auction(auction)

      bid =
        create_bid(1.25, nil, supplier.company_id, fuel_id, auction)
        |> Auctions.place_bid()

      bid2 =
        create_bid(1.25, nil, supplier2.company_id, fuel_id, auction)
        |> Auctions.place_bid()

      Auctions.end_auction(auction)
      {:ok, %{bid: bid, bid2: bid2}}
    end

    test "supplier view of decision period", %{auction: auction, supplier: supplier} do
      login_user(supplier)
      AuctionShowPage.visit(auction.id)
      assert AuctionShowPage.auction_status() == "DECISION"
      assert AuctionShowPage.auction_bid_status() =~ "Your bid is the best overall offer"
    end

    test "buyer view of decision period", %{auction: auction, bid: bid, bid2: bid2, buyer: buyer} do
      login_user(buyer)
      AuctionShowPage.visit(auction.id)
      assert AuctionShowPage.solution_has_bids?(:best_overall, [bid])
      assert AuctionShowPage.solution_has_bids?(0, [bid2])
    end

    test "buyer selects best solution", %{
      auction: auction,
      bid: bid,
      buyer: buyer,
      supplier: supplier,
      supplier2: supplier2
    } do
      login_user(buyer)
      AuctionShowPage.visit(auction.id)
      AuctionShowPage.select_solution(:best_overall)
      :timer.sleep(100)
      AuctionShowPage.accept_bid()
      :timer.sleep(500)
      assert AuctionShowPage.auction_status() == "CLOSED"
      assert AuctionShowPage.winning_solution_has_bids?([bid])

      in_browser_session(:supplier2, fn ->
        login_user(supplier2)
        AuctionShowPage.visit(auction.id)

        assert AuctionShowPage.auction_bid_status() =~
                 "Regretfully, you were unsuccessful in this auction. Thank you for quoting"

        assert AuctionShowPage.auction_status() == "CLOSED"
      end)

      in_browser_session(:supplier, fn ->
        login_user(supplier)
        AuctionShowPage.visit(auction.id)
        assert AuctionShowPage.auction_bid_status() =~ "You won the auction"
        assert AuctionShowPage.auction_status() == "CLOSED"
      end)
    end

    test "buyer selects other solution and provides comment", %{
      auction: auction,
      bid2: bid2,
      buyer: buyer,
      supplier: supplier,
      supplier2: supplier2,
      supplier3: supplier3
    } do
      login_user(buyer)
      :timer.sleep(200)
      AuctionShowPage.visit(auction.id)
      AuctionShowPage.expand_solution(0)
      AuctionShowPage.select_solution(0)
      :timer.sleep(100)
      AuctionShowPage.enter_solution_comment("Screw you!")
      AuctionShowPage.accept_bid()
      :timer.sleep(500)

      assert AuctionShowPage.auction_status() == "CLOSED"
      assert AuctionShowPage.winning_solution_has_bids?([bid2])

      in_browser_session(:supplier, fn ->
        login_user(supplier)
        AuctionShowPage.visit(auction.id)

        assert AuctionShowPage.auction_bid_status() =~
                 "Regretfully, you were unsuccessful in this auction. Thank you for quoting"

        assert AuctionShowPage.auction_status() == "CLOSED"
      end)

      in_browser_session(:supplier2, fn ->
        login_user(supplier2)
        AuctionShowPage.visit(auction.id)
        :timer.sleep(500)
        assert AuctionShowPage.auction_bid_status() =~ "You won the auction"
        assert AuctionShowPage.auction_status() == "CLOSED"
      end)

      in_browser_session(:supplier3, fn ->
        login_user(supplier3)
        AuctionShowPage.visit(auction.id)
        assert AuctionShowPage.auction_status() == "CLOSED"
      end)
    end

    test "buyer selects best solution and specifies port agent", %{
      auction: auction,
      buyer: buyer
    } do
      login_user(buyer)
      AuctionShowPage.visit(auction.id)
      AuctionShowPage.select_solution(:best_overall)
      :timer.sleep(100)
      AuctionShowPage.enter_port_agent("Test Agent")
      AuctionShowPage.accept_bid()
      :timer.sleep(500)

      AuctionShowPage.visit(auction.id)
      assert AuctionShowPage.port_agent() == "Test Agent"
    end
  end

  describe "barges" do
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
