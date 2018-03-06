defmodule OceanconnectWeb.Api.BidControllerTest do
  use OceanconnectWeb.ConnCase

  setup do
    supplier_company = insert(:company)
    supplier = insert(:user, company: supplier_company)
    buyer = insert(:user)
    auction = insert(:auction, buyer: buyer.company, suppliers: [supplier_company])
    Oceanconnect.Auctions.AuctionsSupervisor.start_child(auction)
    Oceanconnect.Auctions.AuctionBidsSupervisor.start_child(auction.id)
    authed_conn = login_user(build_conn(), supplier)
    bid_params = %{"bid" => %{"amount" => "3.50"}}
    {:ok, %{auction: auction, conn: authed_conn, buyer: buyer, bid_params: bid_params}}
  end

  test "creating a bid for a non-existing auction", %{conn: conn, auction: auction, bid_params: params} do
    fake_auction = %{id: auction.id + 9999, suppliers: auction.suppliers}
    conn = create_post(conn, fake_auction, params)
    assert json_response(conn, 422)
  end

  test "creating a bid for a auction that is not open", %{conn: conn, auction: auction, bid_params: params} do
    conn = create_post(conn, auction, params)
    assert json_response(conn, 422)
  end

  describe "open auction" do
    setup %{auction: auction} do
      auction
      |> Oceanconnect.Auctions.Command.start_auction
      |> Oceanconnect.Auctions.AuctionStore.process_command
      :ok
    end

    test "cannot bid when not logged in ", %{conn: conn, auction: auction, bid_params: params} do
      conn = create_post(conn, auction, params)
      assert json_response(conn, 422)
    end

    test "creating a bid for an auction", %{auction: auction, conn: conn, bid_params: params} do
      conn = create_post(conn, auction, params)
      assert json_response(conn, 200)
    end

    test "creating a bid for a auction as a non supplier", %{auction: auction, bid_params: params} do
      non_participant = insert(:user)
      conn = login_user(build_conn(), non_participant)

      conn = create_post(conn, auction, params)
      assert json_response(conn, 422)
    end

    test "creating a bid for a auction as a buyer", %{buyer: buyer, auction: auction, bid_params: params} do
      conn = login_user(build_conn(), buyer)
      conn = create_post(conn, auction, params)

      assert json_response(conn, 401)
    end
  end

  defp create_post(conn, auction, params) do
    supplier_id = hd(auction.suppliers).id
    post(conn, "#{auction_bid_api_path(conn, :create, auction.id)}?supplier_id=#{supplier_id}", params)
  end
end
