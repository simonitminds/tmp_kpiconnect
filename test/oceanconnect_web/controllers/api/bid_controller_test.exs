defmodule OceanconnectWeb.Api.BidControllerTest do
  use OceanconnectWeb.ConnCase

  setup do
    buyer = insert(:user)
    auction = insert(:auction, buyer: buyer.company)
    Oceanconnect.Auctions.AuctionsSupervisor.start_child(auction)
    authed_conn = login_user(build_conn(), buyer)
    bid_params = %{amount: 3.50}
    {:ok, %{auction: auction, conn: authed_conn, bid_params: bid_params}}
  end

  test "cannot bid when not logged in ", %{conn: conn, auction: auction, bid_params: params} do
    conn = post(build_conn(), auction_bid_api_path(conn, :create, auction), params)
    assert json_response(conn, 422)
  end

  test "creating a bid for an auction", %{auction: auction, conn: conn} do
    conn = post(conn, auction_bid_api_path(conn, :create, auction), %{})
    assert json_response(conn, 200)
  end

  test "creating a bid for a non-existing auction", %{conn: conn, auction: auction, bid_params: params} do
    conn = post(conn, auction_bid_api_path(conn, :create, auction.id + 9999), params)
    assert json_response(conn, 422)
  end

  test "creating a bid for a auction that is not open", %{conn: conn, auction: auction, bid_params: params} do
    conn = post(conn, auction_bid_api_path(conn, :create, auction), params)
    assert json_response(conn, 422)
  end

  test "creating a bid for a auction as a non supplier", %{conn: conn, auction: auction, bid_params: params} do
    auction
    |> Command.start_auction
    |> AuctionStore.process_command

    conn = post(conn, auction_bid_api_path(conn, :create, auction), params)
    assert json_response(conn, 422)
  end

  test "creating a bid for a auction as a buyer" do

  end
end
