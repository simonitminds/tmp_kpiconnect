defmodule OceanconnectWeb.Admin.FuelIndexControllerTest do
  use OceanconnectWeb.ConnCase

  alias Oceanconnect.Auctions

  @invalid_attrs %{name: nil, code: nil, fuel_id: nil, port_id: nil}
  @update_attrs %{name: "some new name"}

  setup do
    admin_user = insert(:user, is_admin: true)
    fuel_index = insert(:fuel_index)
    fuel = insert(:fuel)
    port = insert(:port)

    conn =
      build_conn()
      |> login_user(admin_user)

    {:ok, %{conn: conn, fuel_index: fuel_index, fuel: fuel, port: port}}
  end

  describe "index" do
    test "lists paginated fuel index entries", %{conn: conn} do
      conn = get(conn, admin_fuel_index_path(conn, :index))
      assert html_response(conn, 200) =~ "Fuel Index Entries"
      assert conn.assigns.page_size == 10
    end
  end

  describe "new fuel_index" do
    test "renders form", %{conn: conn} do
      conn = get(conn, admin_fuel_index_path(conn, :new))
      assert html_response(conn, 200) =~ "New Fuel Index Entry"
    end
  end

  describe "create fuel_index" do
    test "redirects to index when data is valid", %{conn: conn, fuel: fuel, port: port} do
      conn =
        post(
          conn,
          admin_fuel_index_path(conn, :create,
            fuel_index: %{
              "name" => "some name",
              "code" => 1234,
              "fuel_id" => fuel.id,
              "port_id" => port.id
            }
          )
        )

      assert redirected_to(conn) == admin_fuel_index_path(conn, :index)
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, admin_fuel_index_path(conn, :create), fuel_index: @invalid_attrs)
      assert html_response(conn, 200) =~ "New Fuel Index Entry"
    end
  end

  describe "edit fuel_index" do
    test "renders form for editing chosen fuel_index", %{conn: conn, fuel_index: fuel_index} do
      conn = get(conn, admin_fuel_index_path(conn, :edit, fuel_index))
      assert html_response(conn, 200) =~ "Edit Fuel Index Entry"
    end
  end

  describe "update fuel_index" do
    test "redirects to index when data is valid", %{conn: conn, fuel_index: fuel_index} do
      conn =
        put(conn, admin_fuel_index_path(conn, :update, fuel_index), fuel_index: @update_attrs)

      assert redirected_to(conn) == admin_fuel_index_path(conn, :index)
    end

    test "renders errors when data is invalid", %{conn: conn, fuel_index: fuel_index} do
      conn =
        put(conn, admin_fuel_index_path(conn, :update, fuel_index), fuel_index: @invalid_attrs)

      assert html_response(conn, 200) =~ "Edit Fuel Index Entry"
    end
  end

  describe "delete fuel_index" do
    test "deletes chosen fuel_index", %{conn: conn, fuel_index: fuel_index} do
      conn = delete(conn, admin_fuel_index_path(conn, :delete, fuel_index))
      assert redirected_to(conn) == admin_fuel_index_path(conn, :index)

      assert_error_sent(404, fn ->
        get(conn, admin_fuel_index_path(conn, :edit, fuel_index))
      end)
    end
  end

  describe "deactivate fuel_index" do
    test "deactivates chosen fuel_index", %{conn: conn, fuel_index: fuel_index} do
      conn = post(conn, admin_fuel_index_path(conn, :deactivate, fuel_index))
      assert redirected_to(conn) == admin_fuel_index_path(conn, :index)
      fuel_index = Auctions.get_fuel_index!(fuel_index.id)
      assert fuel_index.is_active == false
    end
  end

  describe "activate fuel_index" do
    test "activates chosen fuel_index", %{conn: conn, fuel_index: fuel_index} do
      conn = post(conn, admin_fuel_index_path(conn, :activate, fuel_index))
      assert redirected_to(conn) == admin_fuel_index_path(conn, :index)
      fuel_index = Auctions.get_fuel_index!(fuel_index.id)
      assert fuel_index.is_active == true
    end
  end
end
