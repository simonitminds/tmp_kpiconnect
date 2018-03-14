defmodule OceanconnectWeb.Api.AuctionControllerTest do
  use OceanconnectWeb.ConnCase

  setup do
    buyer_company = insert(:company, is_supplier: true)
    buyer = insert(:user, company: buyer_company)
    supplier_company = insert(:company, is_supplier: true)
    port = insert(:port, companies: [buyer_company, supplier_company])
    authed_conn = OceanconnectWeb.Plugs.Auth.api_login(build_conn(), buyer)
    auction = insert(:auction, port: port, buyer: buyer_company, suppliers: [supplier_company])
    {:ok, conn: authed_conn, auction: auction, buyer: buyer_company}
  end

  test "user must be authenticated", %{auction: auction} do
    conn = build_conn()
    conn = get conn, auction_api_path(conn, :index, %{"user_id" => auction.buyer_id})
    assert conn.resp_body == "\"Unauthorized\""
  end

  describe "index" do
    test "user can view only auctions they are participating in", %{auction: auction, conn: conn, buyer: buyer} do
      auction_as_supplier = insert(:auction, suppliers: [buyer])
      insert(:auction)
      new_conn = get conn, auction_api_path(conn, :index, %{"user_id" => auction.buyer_id})
      auctions = new_conn.assigns.data
      assert Enum.all?(auctions, fn(a) -> a.id in [auction.id, auction_as_supplier.id] end)
      assert length(auctions) == 2
    end
  end
end
