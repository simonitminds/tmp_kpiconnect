defmodule OceanconnectWeb.Api.AuctionBargesControllerTest do
  use OceanconnectWeb.ConnCase

  setup do
    buyer_company = insert(:company, is_supplier: true)
    supplier_company = insert(:company, is_supplier: true)
    supplier = insert(:user, company: supplier_company)
    port = insert(:port, companies: [buyer_company, supplier_company])
    authed_conn = OceanconnectWeb.Plugs.Auth.api_login(build_conn(), supplier)
    auction = insert(:auction, port: port, buyer: buyer_company, suppliers: [supplier_company])
    {:ok, conn: authed_conn, auction: auction, supplier: supplier}
  end

  test "user must be authenticated", %{auction: auction} do
    conn = build_conn()
    conn = get conn, auction_barges_api_submit_path(conn, :submit, auction.id, 1)
    assert conn.resp_body == "\"Unauthorized\""
  end

  describe "submit" do
    test "supplier can submit barge for approval", %{auction: auction, conn: conn, supplier: supplier} do
      boaty = insert(:barge, name: "Boaty", imo_number: "1234568", companies: [supplier.company])
      new_conn = post conn, auction_barges_api_submit_path(conn, :submit, auction.id, boaty.id)
      payload = new_conn.assigns.data
      assert length(payload.submitted_barges) == 1

      first_barge = hd(payload.submitted_barges)
      assert first_barge.name == boaty.name
      assert first_barge.imo_number == boaty.imo_number
    end

    test "supplier can not submit other company's barges", %{auction: auction, conn: conn} do
      boaty = insert(:barge, name: "Boaty", imo_number: "1234568")
      new_conn = post conn, auction_barges_api_submit_path(conn, :submit, auction.id, boaty.id)
      assert json_response(new_conn, 422) == %{"success" => false, "message" => "Invalid bid"}
    end
  end
end
