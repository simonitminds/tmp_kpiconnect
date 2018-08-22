defmodule OceanconnectWeb.Api.PortAgentControllerTest do
  use OceanconnectWeb.ConnCase

  setup do
    buyer_company = insert(:company, is_supplier: true)
    buyer = insert(:user, company: buyer_company)
    authed_conn = OceanconnectWeb.Plugs.Auth.api_login(build_conn(), buyer)
    auction = insert(:auction, buyer: buyer_company)
    {:ok, conn: authed_conn, auction: auction, buyer: buyer_company}
  end

  test "user must be authenticated", %{auction: auction} do
    conn = build_conn()
    conn = post(conn, port_agent_api_path(conn, :update, auction), port_agent: "Test Agent")
    assert conn.resp_body == "\"Unauthorized\""
  end

  test "buyer can set port agent during winning bid selection", %{auction: auction, conn: conn} do
    new_conn = post(conn, port_agent_api_path(conn, :update, auction), port_agent: "Test Agent")
    updated_auction = Oceanconnect.Repo.get(Oceanconnect.Auctions.Auction, auction.id)
    assert json_response(new_conn, 200)
    assert updated_auction.port_agent == "Test Agent"
  end
end
