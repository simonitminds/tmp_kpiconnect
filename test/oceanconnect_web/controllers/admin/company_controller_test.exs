defmodule OceanconnectWeb.Admin.CompanyControllerTest do
  use OceanconnectWeb.ConnCase

  alias Oceanconnect.Accounts

  @update_attrs %{name: "some updated name"}
  @invalid_attrs %{name: nil}

  setup do
    user = insert(:user, password: "password", is_admin: "true")

    company =
      insert(:company)
      |> Oceanconnect.Repo.preload(:broker_entity)

    conn =
      build_conn()
      |> login_user(user)

    {:ok, %{conn: conn, company: company}}
  end

  describe "index" do
    test "lists paginated companys", %{conn: conn} do
      conn = get(conn, admin_company_path(conn, :index))
      assert html_response(conn, 200) =~ "Companies"
      assert conn.assigns.page_size == 10
    end
  end

  describe "new company" do
    test "renders form", %{conn: conn} do
      conn = get(conn, admin_company_path(conn, :new))
      assert html_response(conn, 200) =~ "New Company"
    end
  end

  describe "create company" do
    test "redirects to index when data is valid", %{conn: conn, company: company} do
      company_params = string_params_for(:company, broker_entity_id: company.broker_entity_id)
      conn = post(conn, admin_company_path(conn, :create), company: company_params)

      assert redirected_to(conn) == admin_company_path(conn, :index)

      conn = get(conn, admin_company_path(conn, :index))
      assert html_response(conn, 200) =~ "Companies"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, admin_company_path(conn, :create), company: @invalid_attrs)
      assert html_response(conn, 200) =~ "New Company"
    end
  end

  describe "edit company" do
    test "renders form for editing chosen company", %{conn: conn, company: company} do
      conn = get(conn, admin_company_path(conn, :edit, company))
      assert html_response(conn, 200) =~ "Edit Company"
    end
  end

  describe "update company" do
    test "redirects to index when data is valid", %{conn: conn, company: company} do
      conn = put(conn, admin_company_path(conn, :update, company), company: @update_attrs)
      assert redirected_to(conn) == admin_company_path(conn, :index)

      conn = get(conn, admin_company_path(conn, :index))
      assert html_response(conn, 200) =~ "some updated name"
    end

    test "renders errors when data is invalid", %{conn: conn, company: company} do
      conn = put(conn, admin_company_path(conn, :update, company), company: @invalid_attrs)
      assert html_response(conn, 200) =~ "Edit Company"
    end
  end

  describe "delete company" do
    test "deletes chosen company", %{conn: conn, company: company} do
      conn = delete(conn, admin_company_path(conn, :delete, company))
      assert redirected_to(conn) == admin_company_path(conn, :index)

      assert_error_sent(404, fn ->
        get(conn, admin_company_path(conn, :edit, company))
      end)
    end
  end

  describe "deactivate company" do
    test "deactivates chosen company", %{conn: conn, company: company} do
      conn = post(conn, admin_company_path(conn, :deactivate, company))
      assert redirected_to(conn) == admin_company_path(conn, :index)
      company = Accounts.get_company!(company.id)
      assert company.is_active == false
    end
  end

  describe "activate company" do
    test "activates chosen company", %{conn: conn, company: company} do
      conn = post(conn, admin_company_path(conn, :activate, company))
      assert redirected_to(conn) == admin_company_path(conn, :index)
      company = Accounts.get_company!(company.id)
      assert company.is_active == true
    end
  end
end
