defmodule OceanconnectWeb.Api.PortSupplierControllerTest do
  use OceanconnectWeb.ConnCase

  setup do
    buyer_company = insert(:company, is_supplier: true)
    buyer = insert(:user, company: buyer_company)
    _vessel = insert(:vessel, company: buyer_company)
    supplier_companies = insert_list(2, :company, is_supplier: true)
    different_port_supplier = insert(:company, is_supplier: true)

    port = insert(:port, companies: supplier_companies ++ [buyer_company])
    _different_port = insert(:port, companies: [different_port_supplier])
    authed_conn = OceanconnectWeb.Plugs.Auth.api_login(build_conn(), buyer)

    {:ok,
     conn: authed_conn,
     port_suppliers: supplier_companies,
     port: port,
     buyer_company: buyer_company,
     different_port_supplier: different_port_supplier}
  end

  describe "suppliers for port" do
    test "lists all suppliers for a port", %{
      conn: conn,
      buyer_company: buyer_company,
      port_suppliers: port_suppliers,
      port: port
    } do
      conn = get(conn, port_supplier_path(conn, :index, port, %{"buyer_id" => buyer_company.id}))

      assert json_response(conn, 200)
      assert conn.assigns[:suppliers] == port_suppliers
    end

    test "does not include suppliers from other ports", %{
      conn: conn,
      buyer_company: buyer_company,
      different_port_supplier: different_port_supplier,
      port: port
    } do
      conn = get(conn, port_supplier_path(conn, :index, port, %{"buyer_id" => buyer_company.id}))

      refute different_port_supplier in conn.assigns[:suppliers]
    end

    test "does not include the buyer's company", %{
      conn: conn,
      buyer_company: buyer_company,
      port: port
    } do
      conn = get(conn, port_supplier_path(conn, :index, port, %{"buyer_id" => buyer_company.id}))

      refute buyer_company in conn.assigns[:suppliers]
    end
  end
end
