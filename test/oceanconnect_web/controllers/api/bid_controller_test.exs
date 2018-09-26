defmodule OceanconnectWeb.Api.BidControllerTest do
  use OceanconnectWeb.ConnCase
  alias Oceanconnect.Auctions

  setup do
    supplier_company = insert(:company, is_supplier: true)
    supplier2_company = insert(:company, is_supplier: true)
    supplier = insert(:user, company: supplier_company)
    buyer = insert(:user)

    auction =
      insert(:auction, buyer: buyer.company, suppliers: [supplier_company, supplier2_company])

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
    bid_params = %{"bid" => %{"amount" => "3.50", "min_amount" => ""}}

    {:ok,
     %{
       auction: auction,
       conn: authed_conn,
       buyer: buyer,
       bid_params: bid_params,
       supplier_company: supplier_company,
       supplier2_company: supplier2_company
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
      bid_params: params
    } do
      updated_params = Map.put(params, "bid", %{"amount" => "2.95", "min_amount" => ""})
      conn = create_post(conn, auction, updated_params)
      assert json_response(conn, 422) == %{"success" => false, "message" => "Invalid bid"}
    end

    test "creating a bid for an auction", %{auction: auction, conn: conn, bid_params: params} do
      conn = create_post(conn, auction, params)

      assert json_response(conn, 200) == %{
               "success" => true,
               "message" => "Bid successfully placed"
             }
    end

    test "creating a minimum bid with no bid for an auction", %{auction: auction, conn: conn} do
      conn = create_post(conn, auction, %{"bid" => %{"amount" => "", "min_amount" => "9.00"}})

      assert json_response(conn, 200) == %{
               "success" => true,
               "message" => "Bid successfully placed"
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

    test "creating a bid for an auction that doesn't allow traded bids", %{
      auction: auction,
      conn: conn,
      bid_params: params
    } do
      params = put_in(params["bid"]["is_traded_bid"], "true")
      conn = create_post(conn, auction, params)

      assert json_response(conn, 422) == %{
               "success" => false,
               "message" => "Auction not accepting traded bids"
             }
    end
  end

  describe "select winning bid" do
    setup %{
      auction: auction,
      buyer: buyer,
      supplier_company: supplier_company,
      supplier2_company: supplier2_company
    } do
      Auctions.start_auction(auction)
      bid = Auctions.place_bid(auction, %{"amount" => 1.25}, supplier_company.id)
      Auctions.place_bid(auction, %{"amount" => 1.25}, supplier2_company.id)
      authed_conn = OceanconnectWeb.Plugs.Auth.api_login(build_conn(), buyer)
      Auctions.end_auction(auction)
      {:ok, %{conn: authed_conn, bid: bid}}
    end

    test "buyer selects winning bid", %{auction: auction, conn: conn, bid: bid} do
      base_route = auction_bid_api_path(conn, :select_bid, auction.id, bid.id)
      new_conn = post(conn, "#{base_route}?comment=test")

      assert json_response(new_conn, 200)

      auction_state = Auctions.get_auction_state!(auction)

      assert auction_state.winning_bid.id == bid.id
      assert auction_state.winning_bid.comment == "test"
      assert auction_state.status == :closed
    end
  end

  defp create_post(conn, auction, params) do
    post(conn, "#{auction_bid_api_path(conn, :create, auction.id)}", params)
  end
end
