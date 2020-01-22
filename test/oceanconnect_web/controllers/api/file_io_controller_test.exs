defmodule OceanconnectWeb.Api.FileIOControllerTest do
  use OceanconnectWeb.ConnCase
  alias Oceanconnect.Auctions
  alias Oceanconnect.Auctions.AuctionSupplierCOQ

  setup do
    buyer_company = insert(:company, is_supplier: true)
    buyer = insert(:user, company: buyer_company)
    supplier_company = insert(:company, is_supplier: true)
    supplier = insert(:user, company: supplier_company)
    supplier2_company = insert(:company, is_supplier: true)
    supplier2 = insert(:user, company: supplier2_company)
    vessel_fuels = insert_list(2, :vessel_fuel)

    auction =
      insert(:auction,
        buyer: buyer_company,
        auction_vessel_fuels: vessel_fuels,
        suppliers: [supplier_company, supplier2_company]
      )
      |> Auctions.fully_loaded()

    {:ok, _pid} =
      start_supervised(
        {Oceanconnect.Auctions.AuctionSupervisor,
         {auction,
          %{
            exclude_children: [
              :auction_reminder_timer,
              :auction_event_handler,
              :auction_scheduler
            ]
          }}}
      )

    authed_conn = OceanconnectWeb.Plugs.Auth.api_login(build_conn(), supplier)

    {:ok,
     conn: authed_conn, auction: auction, buyer: buyer, supplier: supplier, supplier2: supplier2}
  end

  test "user must be authenticated", %{
    auction: auction = %{auction_vessel_fuels: vessel_fuels},
    supplier: supplier
  } do
    fuel = vessel_fuels |> hd() |> Map.get(:fuel)
    spec = "test"
    conn = build_conn()

    conn =
      post(
        conn,
        upload_coq_api_path(conn, :upload_coq, auction.id, supplier.id, fuel.id)
      )

    assert conn.resp_body == "\"Unauthorized\""
  end

  describe "upload_coq" do
    test "supplier can submit barge for approval", %{
      auction: auction,
      conn: conn,
      supplier: supplier
    } do
    end

    test "supplier can not submit other company's barges", %{auction: auction, conn: conn} do
    end
  end
end
