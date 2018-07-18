defmodule OceanconnectWeb.Api.CompanyBargesControllerTest do
  use OceanconnectWeb.ConnCase

  setup do
    other_company = insert(:company)
    supplier_company = insert(:company, is_supplier: true)
    supplier = insert(:user, company: supplier_company)

    barges = [
      insert(:barge, companies: [supplier_company]),
      insert(:barge, companies: [supplier_company]),
      insert(:barge, companies: [supplier_company])
    ]
    other_barges = [
      insert(:barge, companies: [other_company])
    ]

    authed_conn = OceanconnectWeb.Plugs.Auth.api_login(build_conn(), supplier)
    {:ok,
      conn: authed_conn,
      supplier: supplier,
      company: supplier_company,
      other_company: other_company,
      barges: barges,
      other_barges: other_barges,
    }
  end

  test "user must be authenticated", %{company: company} do
    conn = build_conn()
    conn = get conn, company_barges_api_path(conn, :index, company.id)
    assert conn.resp_body == "\"Unauthorized\""
  end

  test "user must belong to the requested company", %{conn: conn, other_company: other_company} do
    conn = get conn, company_barges_api_path(conn, :index, other_company.id)
    assert conn.resp_body == "\"Unauthorized\""
  end

  # /companies/:company_id/barges
  describe "index" do
    test "user can see all barges associated with their company", %{conn: conn, company: supplier_company, barges: supplier_barges, other_barges: other_barges} do
      new_conn = get conn, company_barges_api_path(conn, :index, supplier_company.id)
      barge_ids = new_conn.assigns.data
      |> Enum.map(&(&1.id))

      assert barge_ids == Enum.map(supplier_barges, &(&1.id))
      assert barge_ids != Enum.map(other_barges, &(&1.id))
    end
  end
end
