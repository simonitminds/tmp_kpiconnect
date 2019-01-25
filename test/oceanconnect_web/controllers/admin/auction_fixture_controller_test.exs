defmodule OceanconnectWeb.Admin.FuelControllerTest do
  use OceanconnectWeb.ConnCase
  alias Oceanconnect.Auctions.{AuctionFixture}

  setup do
    user = insert(:user, password: "password", is_admin: "true")

    conn =
      build_conn()
      |> login_user(user)

    non_admin = insert(:user, password: "password", is_admin: "false")

    non_admin_conn =
      build_conn()
      |> login_user(non_admin)

    auction = insert(:auction)
    insert(:auction_fixture, auction: auction)

    {:ok, %{conn: conn, non_admin_conn: non_admin_conn, auction: auction}}
  end

  describe "index" do
    test "lists fixtures", %{conn: conn, auction: auction} do
      final_conn = get(conn, admin_auction_fixtures_path(conn, :index, auction.id))
      response = html_response(final_conn, 200)
      assert response =~ "Auction Fixtures"
      assert %{fixtures: [%AuctionFixture{}]} = final_conn.assigns
    end

    # test "redirects without admin an session", %{non_admin_conn: non_admin_conn, auction: auction} do
    #   conn = get(non_admin_conn, admin_auction_fixtures_path(non_admin_conn, :index, auction.id))
    #   assert redirected_to(conn) == session_path(conn, :index)
    # end
  end
end
