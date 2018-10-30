defmodule OceanconnectWeb.Api.BidControllerTest do
  use OceanconnectWeb.ConnCase
  alias Oceanconnect.Auctions

  setup do
    supplier_company = insert(:company, is_supplier: true)
    supplier2_company = insert(:company, is_supplier: true)
    supplier = insert(:user, company: supplier_company)
    buyer = insert(:user)

    fuel1 = insert(:fuel)
    fuel2 = insert(:fuel)
    fuel1_id = "#{fuel1.id}"
    fuel2_id = "#{fuel2.id}"

    auction =
      insert(
        :auction,
        buyer: buyer.company,
        suppliers: [supplier_company, supplier2_company],
        auction_vessel_fuels: [
          build(:vessel_fuel, fuel: fuel1),
          build(:vessel_fuel, fuel: fuel2)
        ]
      )
      |> Auctions.fully_loaded()

    {:ok, _pid} =
      start_supervised(
        {Oceanconnect.Auctions.AuctionSupervisor,
         {auction,
          %{
            exclude_children: [
              :auction_reminder_timer,
              :auction_event_handler,
              :auction_scheduler
            ]
          }}}
      )

    authed_conn = OceanconnectWeb.Plugs.Auth.api_login(build_conn(), supplier)
    bid_params = %{"bids" => %{fuel1_id => %{"amount" => "3.50", "min_amount" => "", "allow_split" => true}}}

    {:ok,
     %{
       auction: auction,
       conn: authed_conn,
       buyer: buyer,
       bid_params: bid_params,
       supplier_company: supplier_company,
       supplier2_company: supplier2_company,
       fuel1_id: fuel1_id,
       fuel2_id: fuel2_id
     }}
  end

  test "creating a bid for a non-existing auction", %{
    conn: conn,
    auction: auction,
    bid_params: params
  } do
    fake_auction = %{id: auction.id + 9999, suppliers: auction.suppliers}
    conn = create_post(conn, fake_auction, params)
    assert json_response(conn, 422) == %{"success" => false, "message" => "Invalid bid"}
  end

  test "error when creating bid for auction in decision", %{
    conn: conn,
    auction: auction,
    bid_params: params
  } do
    updated_auction =
      auction
      |> Auctions.start_auction()
      |> Auctions.end_auction()

    conn = create_post(conn, updated_auction, params)

    assert json_response(conn, 409) == %{
             "success" => false,
             "message" => "Auction moved to decision before bid was received"
           }
  end

  test "error when creating bid for auction after decision", %{
    conn: conn,
    auction: auction,
    bid_params: params
  } do
    updated_auction =
      auction
      |> Auctions.start_auction()
      |> Auctions.end_auction()
      |> Auctions.expire_auction()

    conn = create_post(conn, updated_auction, params)
    assert json_response(conn, 422) == %{"success" => false, "message" => "Invalid bid"}
  end

  describe "open auction" do
    setup %{auction: auction} do
      Auctions.start_auction(auction)
      :ok
    end

    test "cannot bid when not logged in ", %{auction: auction, bid_params: params} do
      conn = create_post(build_conn(), auction, params)
      assert json_response(conn, 401)
    end

    test "cannot enter bids of non $0.25 increments ", %{
      conn: conn,
      auction: auction,
      bid_params: params,
      fuel1_id: fuel1_id
    } do
      updated_params = Map.put(params, "bids", %{ fuel1_id => %{"amount" => "2.95", "min_amount" => "", "allow_split" => "true"}})
      conn = create_post(conn, auction, updated_params)
      assert %{"success" => false, "message" => "Invalid bid"} = json_response(conn, 422)
    end

    test "creating a bid for an auction", %{auction: auction, conn: conn, bid_params: params} do
      conn = create_post(conn, auction, params)

      assert json_response(conn, 200) == %{
               "success" => true,
               "message" => "Bids successfully placed"
             }
    end

    test "creating multiple bids in a single request", %{auction: auction, conn: conn, fuel1_id: fuel1_id, fuel2_id: fuel2_id} do
      bid_params = %{"bids" => %{
        fuel1_id => %{"amount" => "3.50", "min_amount" => "", "allow_split" => "true"},
        fuel2_id => %{"amount" => "2.50", "min_amount" => "1.00", "allow_split" => "true"},
      }}

      conn = create_post(conn, auction, bid_params)

      assert json_response(conn, 200) == %{
               "success" => true,
               "message" => "Bids successfully placed"
             }
    end

    test "creating a minimum bid with no bid for an auction", %{auction: auction, conn: conn, fuel1_id: fuel1_id} do
      conn = create_post(conn, auction, %{"bids" => %{ fuel1_id => %{"amount" => "", "min_amount" => "9.00", "allow_split" => "true"}}})

      assert json_response(conn, 200) == %{
               "success" => true,
               "message" => "Bids successfully placed"
             }
    end

    test "creating a bid for an auction as a non supplier", %{
      auction: auction,
      bid_params: params
    } do
      non_participant_company = insert(:company)
      non_participant = insert(:user, company: non_participant_company)
      conn = OceanconnectWeb.Plugs.Auth.api_login(build_conn(), non_participant)

      conn = post(conn, "#{auction_bid_api_path(conn, :create, auction.id)}", params)
      assert json_response(conn, 422) == %{"success" => false, "message" => "Invalid bid"}
    end

    test "creating a bid for an auction as a buyer", %{
      buyer: buyer,
      auction: auction,
      bid_params: params
    } do
      conn = OceanconnectWeb.Plugs.Auth.api_login(build_conn(), buyer)
      conn = post(conn, "#{auction_bid_api_path(conn, :create, auction.id)}", params)

      assert json_response(conn, 422) == %{"success" => false, "message" => "Invalid bid"}
    end

    test "creating a bid for an auction that doesn't allow traded bids", %{
      auction: auction,
      conn: conn,
      bid_params: params
    } do
      params = put_in(params["is_traded_bid"], true)
      conn = create_post(conn, auction, params)

      assert json_response(conn, 422) == %{
               "success" => false,
               "message" => "Auction not accepting traded bids"
             }
    end

    test "creating a non-splittable bid", %{
      auction: auction,
      conn: conn,
      fuel1_id: fuel1_id,
      fuel2_id: fuel2_id
    } do
      params = %{"bids" => %{
        fuel1_id => %{"amount" => "3.50", "min_amount" => "", "allow_split" => "false"},
        fuel2_id => %{"amount" => "2.50", "min_amount" => "1.00", "allow_split" => "false"},
      }}
      conn = create_post(conn, auction, params)

      assert json_response(conn, 200) == %{
               "success" => true,
               "message" => "Bids successfully placed"
             }
    end

    test "creating a bid for an auction in decision", %{
      auction: auction,
      conn: conn,
      bid_params: params
    } do
      Auctions.end_auction(auction)
      conn = create_post(conn, auction, params)

      assert json_response(conn, 409) == %{
               "success" => false,
               "message" => "Auction moved to decision before bid was received"
             }
    end
  end

  describe "revoking bids" do
    setup %{auction: auction, conn: conn, fuel1_id: fuel1_id, fuel2_id: fuel2_id} do
      Auctions.start_auction(auction)

      bid_params = %{"bids" => %{
        fuel1_id => %{"amount" => "3.50", "min_amount" => "", "allow_split" => "true"},
        fuel2_id => %{"amount" => "2.50", "min_amount" => "1.00", "allow_split" => "true"},
      }}

      create_post(conn, auction, bid_params)

      :ok
    end

    test "revoking a bid for a product from a supplier", %{auction: auction, conn: conn, fuel1_id: fuel1_id} do
      conn = revoke_post(conn, auction, %{"product" => fuel1_id})

      assert json_response(conn, 200) == %{
               "success" => true,
               "message" => "Bid successfully revoked"
             }
    end

    test "revoking a bid for an auction in decision", %{
      auction: auction,
      conn: conn,
      fuel1_id: fuel1_id
    } do
      Auctions.end_auction(auction)
      :timer.sleep(100)

      conn = revoke_post(conn, auction, %{"product" => fuel1_id})

      assert json_response(conn, 409) == %{
               "success" => false,
               "message" => "Auction moved to decision before request was received"
             }
    end
  end

  describe "select winning bid" do
    setup %{
      auction: auction,
      buyer: buyer,
      supplier_company: supplier_company,
      fuel1_id: fuel1_id
    } do
      Auctions.start_auction(auction)
      bid = create_bid(1.25, nil, supplier_company.id, fuel1_id, auction)
      |> Auctions.place_bid(nil)
      authed_conn = OceanconnectWeb.Plugs.Auth.api_login(build_conn(), buyer)
      Auctions.end_auction(auction)
      {:ok, %{conn: authed_conn, bid: bid}}
    end

    test "buyer selects winning bid", %{auction: auction, conn: conn, bid: bid} do
      new_conn = post(conn, auction_bid_api_path(conn, :select_solution, auction.id), %{comment: "test", bid_ids: [bid.id]})

      assert json_response(new_conn, 200)

      auction_state = Auctions.get_auction_state!(auction)

      assert bid in auction_state.winning_solution.bids
      assert auction_state.winning_solution.comment == "test"
      assert auction_state.status == :closed
    end
  end

  defp create_post(conn, auction, params) do
    post(conn, "#{auction_bid_api_path(conn, :create, auction.id)}", params)
  end

  defp revoke_post(conn, auction, params) do
    post(conn, "#{auction_bid_api_path(conn, :revoke, auction.id)}", params)
  end
end
