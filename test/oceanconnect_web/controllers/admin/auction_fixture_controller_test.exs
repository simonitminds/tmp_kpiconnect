defmodule OceanconnectWeb.Admin.FixtureControllerTest do
  use OceanconnectWeb.ConnCase
  alias Oceanconnect.Auctions.{AuctionFixture}

  setup do
    user = insert(:user, password: "password", is_admin: "true")

    admin_conn =
      build_conn()
      |> login_user(user)

    non_admin = insert(:user, password: "password", is_admin: "false")

    non_admin_conn =
      build_conn()
      |> login_user(non_admin)

    auction = insert(:auction)

    {:ok, %{admin_conn: admin_conn, non_admin_conn: non_admin_conn, auction: auction}}
  end

  describe "index" do
    test "lists fixtures", %{admin_conn: admin_conn, auction: auction} do
      insert(:auction_fixture, auction: auction)

      close_auction!(auction)

      final_conn = get(admin_conn, admin_auction_fixtures_path(admin_conn, :index, auction.id))
      response = html_response(final_conn, 200)
      assert response =~ "Fixtures"
      assert %{fixtures: [%AuctionFixture{}]} = final_conn.assigns
    end

    test "redirects without admin an session", %{non_admin_conn: non_admin_conn, auction: auction} do
      conn = get(non_admin_conn, admin_auction_fixtures_path(non_admin_conn, :index, auction.id))
      assert redirected_to(conn) == auction_path(conn, :index)
    end

    test "renders for expired auctions", %{auction: auction, admin_conn: admin_conn} do
      expire_auction!(auction)

      final_conn = get(admin_conn, admin_auction_fixtures_path(admin_conn, :index, auction.id))

      assert html_response(final_conn, 200)
      assert %{fixtures: []} = final_conn.assigns
    end

    test "renders for closed", %{auction: auction, admin_conn: admin_conn} do
      close_auction!(auction)

      final_conn = get(admin_conn, admin_auction_fixtures_path(admin_conn, :index, auction.id))

      assert html_response(final_conn, 200)
      assert %{fixtures: []} = final_conn.assigns
    end

    test "redirects for canceled", %{auction: auction, admin_conn: admin_conn} do
      cancel_auction!(auction)

      final_conn = get(admin_conn, admin_auction_fixtures_path(admin_conn, :index, auction.id))

      assert redirected_to(final_conn) == auction_path(final_conn, :index)
    end

    test "redirects for open", %{auction: auction, admin_conn: admin_conn} do
      start_auction!(auction)

      final_conn = get(admin_conn, admin_auction_fixtures_path(admin_conn, :index, auction.id))
      assert redirected_to(final_conn) == auction_path(final_conn, :index)
    end

    test "redirects for pending", %{auction: auction, admin_conn: admin_conn} do
      final_conn = get(admin_conn, admin_auction_fixtures_path(admin_conn, :index, auction.id))
      assert redirected_to(final_conn) == auction_path(final_conn, :index)
    end
  end
end
