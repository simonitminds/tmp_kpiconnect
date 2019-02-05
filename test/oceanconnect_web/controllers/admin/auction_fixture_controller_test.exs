defmodule OceanconnectWeb.Admin.FixtureControllerTest do
  use OceanconnectWeb.ConnCase
  alias Oceanconnect.Auctions
  alias Oceanconnect.Auctions.{AuctionFixture, AuctionEvent, AuctionEventStorage, AuctionStateActions}

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

    test "redirects for pending" do
      assert false, "Needs Implemented"
    end

    def start_auction!(auction) do
      state = Oceanconnect.Auctions.AuctionStore.AuctionState.from_auction(auction)
      next_state = AuctionStateActions.start_auction(state, auction, nil, true)
      event = AuctionEvent.auction_started(auction, next_state, nil)
      AuctionEventStorage.persist(%AuctionEventStorage{event: event})
    end

    def cancel_auction!(auction) do
      state = Oceanconnect.Auctions.AuctionStore.AuctionState.from_auction(auction)
      new_state = AuctionStateActions.cancel_auction(state)
      AuctionEventStorage.persist(%AuctionEventStorage{event: AuctionEvent.auction_canceled(auction, new_state, nil)})
    end

    def expire_auction!(auction) do
      current_state = Auctions.get_auction_state!(auction)
      new_state = AuctionStateActions.expire_auction(current_state)
      event = AuctionEvent.auction_expired(auction, new_state)
      AuctionEventStorage.persist(%AuctionEventStorage{event: event, auction_id: auction.id})
    end

    def close_auction!(auction) do
      supplier_id = hd(auction.suppliers).id
      vessel_fuel_id = hd(auction.auction_vessel_fuels).id
      bid = create_bid(3.50, 3.50, supplier_id, vessel_fuel_id, auction)
      state = Oceanconnect.Auctions.AuctionStore.AuctionState.from_auction(auction)
      state = AuctionStateActions.start_auction(state, auction, nil, false)
      {_product_state, _events, new_state} = AuctionStateActions.process_bid(state, bid)
      solution = new_state.solutions.best_overall
      state  = AuctionStateActions.select_winning_solution(solution, new_state)
      event = AuctionEvent.winning_solution_selected(solution, "", state, nil)
      AuctionEventStorage.persist(%AuctionEventStorage{event: event, auction_id: auction.id})
    end
  end
end
