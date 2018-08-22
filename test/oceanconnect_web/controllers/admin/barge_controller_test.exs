defmodule OceanconnectWeb.Admin.BargeControllerTest do
  use OceanconnectWeb.ConnCase

  alias Oceanconnect.Auctions

  @update_attrs %{imo: 42, name: "some updated name"}
  @invalid_attrs %{imo: nil, name: nil}

  setup do
    user = insert(:user, password: "password", is_admin: "true")

    barge =
      insert(:barge)
      |> Oceanconnect.Repo.preload(:port)

    conn =
      build_conn()
      |> login_user(user)

    {:ok, %{conn: conn, barge: barge}}
  end

  describe "index" do
    test "lists paginated barges", %{conn: conn} do
      conn = get(conn, admin_barge_path(conn, :index))
      assert html_response(conn, 200) =~ "Barges"
      assert conn.assigns.page_size == 10
    end
  end

  describe "new barge" do
    test "renders form", %{conn: conn} do
      conn = get(conn, admin_barge_path(conn, :new))
      assert html_response(conn, 200) =~ "New Barge"
    end
  end

  describe "create barge" do
    test "redirects to index when data is valid", %{conn: conn, barge: barge} do
      barge_params = string_params_for(:barge, port_id: barge.port_id)
      conn = post(conn, admin_barge_path(conn, :create), barge: barge_params)

      assert redirected_to(conn) == admin_barge_path(conn, :index)

      conn = get(conn, admin_barge_path(conn, :index))
      assert html_response(conn, 200) =~ "Barges"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, admin_barge_path(conn, :create), barge: @invalid_attrs)
      assert html_response(conn, 200) =~ "New Barge"
    end
  end

  describe "edit barge" do
    test "renders form for editing chosen barge", %{conn: conn, barge: barge} do
      conn = get(conn, admin_barge_path(conn, :edit, barge))
      assert html_response(conn, 200) =~ "Edit Barge"
    end
  end

  describe "update barge" do
    test "redirects to index when data is valid", %{conn: conn, barge: barge} do
      conn = put(conn, admin_barge_path(conn, :update, barge), barge: @update_attrs)
      assert redirected_to(conn) == admin_barge_path(conn, :index)

      conn = get(conn, admin_barge_path(conn, :index))
      assert html_response(conn, 200) =~ "some updated name"
    end

    test "renders errors when data is invalid", %{conn: conn, barge: barge} do
      conn = put(conn, admin_barge_path(conn, :update, barge), barge: @invalid_attrs)
      assert html_response(conn, 200) =~ "Edit Barge"
    end
  end

  describe "delete barge" do
    test "deletes chosen barge", %{conn: conn, barge: barge} do
      conn = delete(conn, admin_barge_path(conn, :delete, barge))
      assert redirected_to(conn) == admin_barge_path(conn, :index)

      assert_error_sent(404, fn ->
        get(conn, admin_barge_path(conn, :edit, barge))
      end)
    end
  end

  describe "deactivate barge" do
    test "deactivates chosen barge", %{conn: conn, barge: barge} do
      conn = post(conn, admin_barge_path(conn, :deactivate, barge))
      assert redirected_to(conn) == admin_barge_path(conn, :index)
      barge = Auctions.get_barge!(barge.id)
      assert barge.is_active == false
    end
  end

  describe "activate barge" do
    test "activates chosen barge", %{conn: conn, barge: barge} do
      conn = post(conn, admin_barge_path(conn, :activate, barge))
      assert redirected_to(conn) == admin_barge_path(conn, :index)
      barge = Auctions.get_barge!(barge.id)
      assert barge.is_active == true
    end
  end
end
