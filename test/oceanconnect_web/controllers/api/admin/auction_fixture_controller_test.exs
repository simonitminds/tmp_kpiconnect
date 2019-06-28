defmodule OceanconnectWeb.Api.Admin.AuctionFixtureControllerTest do
  use OceanconnectWeb.ConnCase
  alias Oceanconnect.Auctions

  setup do
    user = insert(:user, is_admin: "true")

    admin_conn =
      build_conn()
      |> login_user(user)

    buyer_company = insert(:company)
    insert(:user, company: buyer_company)

    supplier_company = insert(:company, is_supplier: true)
    insert(:user, company: supplier_company)

    auction =
      insert(
        :auction,
        buyer: buyer_company,
        suppliers: [supplier_company]
      )

    auction_state = close_auction!(auction)
    {:ok, auction_fixtures} = Auctions.create_fixtures_from_state(auction_state)
    [auction: auction, fixtures: auction_fixtures]

    {:ok, %{auction: auction, fixtures: auction_fixtures, admin_conn: admin_conn}}
  end

  test "renders an index page of fixtures grouped by auction", %{
    auction: auction,
    admin_conn: conn,
    fixtures: fixtures
  } do
    conn = get(conn, auction_fixture_api_path(conn, :index))
    fixture_payloads = conn.assigns.data

    assert Enum.all?(fixture_payloads, fn payload ->
             payload.auction == auction and payload.fixtures == fixtures
           end)
  end
end
