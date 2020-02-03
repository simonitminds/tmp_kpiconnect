defmodule OceanconnectWeb.FileIOControllerTest do
  use OceanconnectWeb.ConnCase
  alias Oceanconnect.Auctions

  setup do
    buyer_company = insert(:company, is_supplier: true)
    buyer = insert(:user, company: buyer_company)
    supplier_company = insert(:company, is_supplier: true)
    supplier = insert(:user, company: supplier_company)
    supplier2_company = insert(:company, is_supplier: true)
    supplier2 = insert(:user, company: supplier2_company)
    vessel_fuels = insert_list(2, :vessel_fuel)
    fuel = vessel_fuels |> hd() |> Map.get(:fuel)

    auction =
      insert(:auction,
        buyer: buyer_company,
        auction_vessel_fuels: vessel_fuels,
        suppliers: [supplier_company, supplier2_company]
      )
      |> Auctions.fully_loaded()

    existing_coq =
      insert(:auction_supplier_coq, auction: auction, fuel: fuel, supplier: supplier_company)

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

    {:ok,
     %{
       buyer: buyer,
       existing_coq: existing_coq,
       supplier: supplier,
       supplier2: supplier2
     }}
  end

  describe "an admin" do
    setup do
      admin = insert(:user, is_admin: true)

      authed_conn =
        build_conn()
        |> OceanconnectWeb.Plugs.Auth.api_login(admin)
        |> Plug.Conn.put_req_header("content-type", "application/pdf")

      {:ok, %{conn: authed_conn}}
    end

    test "can view coq", %{
      conn: conn,
      existing_coq: %{id: existing_coq_id}
    } do
      conn = get(conn, view_coq_path(conn, :view_coq, existing_coq_id))

      assert 200 == conn.status
    end
  end

  describe "a buyer" do
    setup %{buyer: buyer} do
      authed_conn =
        build_conn()
        |> OceanconnectWeb.Plugs.Auth.api_login(buyer)
        |> Plug.Conn.put_req_header("content-type", "application/pdf")

      {:ok, %{conn: authed_conn}}
    end

    test "can view coq", %{
      conn: conn,
      existing_coq: %{id: existing_coq_id}
    } do
      conn = get(conn, view_coq_path(conn, :view_coq, existing_coq_id))

      assert 200 == conn.status
    end
  end

  describe "a supplier" do
    setup %{supplier: supplier} do
      authed_conn =
        build_conn()
        |> OceanconnectWeb.Plugs.Auth.api_login(supplier)
        |> Plug.Conn.put_req_header("content-type", "application/pdf")

      {:ok, %{conn: authed_conn}}
    end

    test "can view coq", %{
      conn: conn,
      existing_coq: %{id: existing_coq_id}
    } do
      conn = get(conn, view_coq_path(conn, :view_coq, existing_coq_id))

      assert 200 == conn.status
    end

    test "can NOT view coq of other supplier", %{
      supplier2: supplier2,
      existing_coq: %{id: existing_coq_id}
    } do
      authed_conn =
        build_conn()
        |> OceanconnectWeb.Plugs.Auth.api_login(supplier2)

      conn = get(authed_conn, view_coq_path(authed_conn, :view_coq, existing_coq_id))

      assert 401 == conn.status
    end
  end
end
