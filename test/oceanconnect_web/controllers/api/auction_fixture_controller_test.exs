defmodule OceanconnectWeb.Api.AuctionFixtureControllerTest do
  use OceanconnectWeb.ConnCase
  alias Oceanconnect.Auctions

  setup do
    # user = insert(:user, is_admin: "true")

    buyer_company = insert(:company)
    buyer = insert(:user, company: buyer_company)
    insert(:user, company: buyer_company)

    supplier_company = insert(:company, is_supplier: true)
    insert(:user, company: supplier_company)

    auction =
      insert(
        :auction,
        buyer: buyer_company,
        suppliers: [supplier_company],
        finalized: true,
        auction_closed_time: DateTime.utc_now()
      )

    auction_state = close_auction!(auction)
    authed_conn = OceanconnectWeb.Plugs.Auth.api_login(build_conn(), buyer)
    {:ok, auction_fixtures} = Auctions.create_fixtures_from_state(auction_state)
    [auction: auction, fixtures: auction_fixtures]

    {:ok, %{auction: auction, fixtures: auction_fixtures, conn: authed_conn}}
  end

  test "user must be authenticated", %{auction: auction} do
    conn = build_conn()
    conn = get(conn, auction_fixture_api_path(conn, :index, %{"user_id" => auction.buyer_id}))
    assert conn.resp_body == "\"Unauthorized\""
  end

  test "renders an index page of fixtures grouped by auction", %{
    auction: auction,
    conn: conn,
    fixtures: fixtures
  } do
    conn = get(conn, auction_fixture_api_path(conn, :index))
    assert conn.status == 200
    fixture_payload = conn.assigns.data |> List.first()

    assert fixture_payload.auction.id == auction.id

    assert MapSet.equal?(
             MapSet.new(Enum.map(fixtures, & &1.id)),
             MapSet.new(Enum.map(fixture_payload.fixtures, & &1.id))
           )
  end
end
