defmodule OceanconnectWeb.Admin.UserControllerTest do
	use OceanconnectWeb.ConnCase

	alias Oceanconnect.Accounts

  @update_attrs %{email: "some-updated-email@example.com", password: "password"}
  @invalid_attrs %{email: nil}

  setup do
		admin_company = insert(:company)
		company = insert(:company)
    admin_user = insert(:user, password: "password", is_admin: "true", company: admin_company)
		user = insert(:user, company: company)
    conn = build_conn()
    |> login_user(admin_user)
    {:ok, %{conn: conn, user: user}}
  end

  describe "index" do
    test "lists paginated users", %{conn: conn} do
      conn = get conn, admin_user_path(conn, :index)
      assert html_response(conn, 200) =~ "Users"
			assert conn.assigns.page_size == 10
    end
  end

  describe "new user" do
    test "renders form", %{conn: conn} do
      conn = get conn, admin_user_path(conn, :new)
      assert html_response(conn, 200) =~ "New User"
    end
  end

  describe "create user" do
    test "redirects to index when data is valid", %{conn: conn, user: user} do
			user_params = string_params_for(:user)
      conn = post conn, admin_user_path(conn, :create), user: user_params

      assert redirected_to(conn) == admin_user_path(conn, :index)

      conn = get conn, admin_user_path(conn, :index)
      assert html_response(conn, 200) =~ "Users"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post conn, admin_user_path(conn, :create), user: @invalid_attrs
      assert html_response(conn, 200) =~ "New User"
    end
  end

  describe "edit user" do
    test "renders form for editing chosen user", %{conn: conn, user: user} do
      conn = get conn, admin_user_path(conn, :edit, user)
      assert html_response(conn, 200) =~ OceanconnectWeb.Admin.UserView.full_name(user)
    end
  end

  describe "update user" do
    test "redirects to index when data is valid", %{conn: conn, user: user} do
      conn = put conn, admin_user_path(conn, :update, user), user: @update_attrs
      assert redirected_to(conn) == admin_user_path(conn, :index)

      conn = get conn, admin_user_path(conn, :index)
      assert html_response(conn, 200) =~ "Users"
    end

    test "renders errors when data is invalid", %{conn: conn, user: user} do
      conn = put conn, admin_user_path(conn, :update, user), user: @invalid_attrs
      assert html_response(conn, 200) =~ OceanconnectWeb.Admin.UserView.full_name(user)
    end
  end

  describe "delete user" do
    test "deletes chosen user", %{conn: conn, user: user} do
      conn = delete conn, admin_user_path(conn, :delete, user)
      assert redirected_to(conn) == admin_user_path(conn, :index)
      assert user.is_active == false
		end
  end
end
