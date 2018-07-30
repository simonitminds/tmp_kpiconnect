defmodule OceanconnectWeb.Api.AuctionBargesControllerTest do
  use OceanconnectWeb.ConnCase
  alias Oceanconnect.Auctions

  setup do
    buyer_company = insert(:company, is_supplier: true)
    buyer = insert(:user, company: buyer_company)
    supplier_company = insert(:company, is_supplier: true)
    supplier = insert(:user, company: supplier_company)
    port = insert(:port, companies: [buyer_company, supplier_company])
    auction = insert(:auction, port: port, buyer: buyer_company, suppliers: [supplier_company])
    {:ok, _pid} = start_supervised({Oceanconnect.Auctions.AuctionSupervisor, {auction, %{exclude_children: [:auction_event_handler, :auction_scheduler]}}})
    authed_conn = OceanconnectWeb.Plugs.Auth.api_login(build_conn(), supplier)
    {:ok, conn: authed_conn, auction: auction, buyer: buyer, supplier: supplier}
  end

  test "user must be authenticated", %{auction: auction} do
    conn = build_conn()
    conn = post conn, auction_barges_api_submit_path(conn, :submit, auction.id, 1)
    assert conn.resp_body == "\"Unauthorized\""
  end

  describe "submit" do
    test "supplier can submit barge for approval", %{auction: auction, conn: conn, supplier: supplier} do
      boaty = insert(:barge, name: "Boaty", imo_number: "1234568", companies: [supplier.company])
      new_conn = post conn, auction_barges_api_submit_path(conn, :submit, auction.id, boaty.id)
      payload = new_conn.assigns.auction_payload
      assert length(payload.submitted_barges) == 1

      first_barge = hd(payload.submitted_barges)
      assert first_barge.barge.name == boaty.name
      assert first_barge.barge.imo_number == boaty.imo_number
    end

    test "supplier can not submit other company's barges", %{auction: auction, conn: conn} do
      boaty = insert(:barge, name: "Boaty", imo_number: "1234568")
      new_conn = post conn, auction_barges_api_submit_path(conn, :submit, auction.id, boaty.id)
      assert json_response(new_conn, 422) == %{"success" => false, "message" => "Invalid barge"}
    end
  end

  describe "unsubmit" do
    test "supplier can unsubmit barge from approval", %{auction: auction, conn: conn, supplier: supplier} do
      boaty = insert(:barge, name: "Boaty", imo_number: "1234568", companies: [supplier.company])
      post conn, auction_barges_api_submit_path(conn, :submit, auction.id, boaty.id)

      new_conn = post conn, auction_barges_api_unsubmit_path(conn, :unsubmit, auction.id, boaty.id)
      payload = new_conn.assigns.auction_payload
      assert length(payload.submitted_barges) == 0
    end

    test "supplier can not unsubmit other company's barges", %{auction: auction, conn: conn} do
      supplier_company2 = insert(:company, is_supplier: true)
      supplier2 = insert(:user, company: supplier_company2)
      supplier2_conn = OceanconnectWeb.Plugs.Auth.api_login(build_conn(), supplier2)

      boaty = insert(:barge, name: "Boaty", imo_number: "1234568", companies: [supplier_company2])
      post supplier2_conn, auction_barges_api_submit_path(supplier2_conn, :submit, auction.id, boaty.id)

      new_conn = post conn, auction_barges_api_unsubmit_path(conn, :unsubmit, auction.id, boaty.id)
      assert json_response(new_conn, 422) == %{"success" => false, "message" => "Invalid barge"}
    end
  end

  describe "approve" do
    test "buyer can approve submitted barges from supplier", %{auction: auction, conn: supplier_conn, buyer: buyer, supplier: supplier} do
      boaty = insert(:barge, name: "Boaty", imo_number: "1234568", companies: [supplier.company])
      post supplier_conn, auction_barges_api_submit_path(supplier_conn, :submit, auction.id, boaty.id)

      conn = OceanconnectWeb.Plugs.Auth.api_login(build_conn(), buyer)
      new_conn = post conn, auction_barges_api_approve_path(conn, :approve, auction.id, boaty.id)
      payload = new_conn.assigns.auction_payload
      assert length(payload.submitted_barges) == 1

      first = hd(payload.submitted_barges)
      assert first.barge_id == boaty.id
      assert first.approval_status == "APPROVED"
    end

    test "supplier can not approve barges", %{auction: auction, conn: conn, supplier: supplier} do
      boaty = insert(:barge, name: "Boaty", imo_number: "1234568", companies: [supplier.company])
      post conn, auction_barges_api_submit_path(conn, :submit, auction.id, boaty.id)

      insert(:auction_barge, barge: boaty, auction: auction, supplier: supplier.company)
      new_conn = post conn, auction_barges_api_approve_path(conn, :approve, auction.id, boaty.id)
      assert json_response(new_conn, 422) == %{"success" => false, "message" => "Suppliers cannot approve barges"}
    end
  end


  describe "reject" do
    test "buyer can reject submitted barges from supplier", %{auction: auction, conn: supplier_conn, buyer: buyer, supplier: supplier} do
      boaty = insert(:barge, name: "Boaty", imo_number: "1234568", companies: [supplier.company])
      post supplier_conn, auction_barges_api_submit_path(supplier_conn, :submit, auction.id, boaty.id)

      conn = OceanconnectWeb.Plugs.Auth.api_login(build_conn(), buyer)
      new_conn = post conn, auction_barges_api_reject_path(conn, :reject, auction.id, boaty.id)
      payload = new_conn.assigns.auction_payload
      assert length(payload.submitted_barges) == 1

      first = hd(payload.submitted_barges)
      assert first.barge_id == boaty.id
      assert first.approval_status == "REJECTED"
    end

    test "supplier can not reject barges", %{auction: auction, conn: conn, supplier: supplier} do
      boaty = insert(:barge, name: "Boaty", imo_number: "1234568", companies: [supplier.company])
      post conn, auction_barges_api_submit_path(conn, :submit, auction.id, boaty.id)

      insert(:auction_barge, barge: boaty, auction: auction, supplier: supplier.company)
      new_conn = post conn, auction_barges_api_reject_path(conn, :reject, auction.id, boaty.id)
      assert json_response(new_conn, 422) == %{"success" => false, "message" => "Suppliers cannot reject barges"}
    end
  end
end
