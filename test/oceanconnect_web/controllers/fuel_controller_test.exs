defmodule OceanconnectWeb.FuelControllerTest do
  use OceanconnectWeb.ConnCase

  alias Oceanconnect.Auctions

  @create_attrs %{name: "some name"}
  @update_attrs %{name: "some updated name"}
  @invalid_attrs %{name: nil}

  def fixture(:fuel) do
    {:ok, fuel} = Auctions.create_fuel(@create_attrs)

    fuel
  end

  setup do
    user = insert(:user, password: "password")
    conn = build_conn()
    |> login_user(user)
    {:ok, %{conn: conn}}
  end

  describe "index" do
    test "lists all fuels", %{conn: conn} do
      conn = get conn, fuel_path(conn, :index)
      assert html_response(conn, 200) =~ "Listing Fuels"
    end
  end

  describe "new fuel" do
    test "renders form", %{conn: conn} do
      conn = get conn, fuel_path(conn, :new)
      assert html_response(conn, 200) =~ "New Fuel"
    end
  end

  describe "create fuel" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post conn, fuel_path(conn, :create), fuel: @create_attrs

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == fuel_path(conn, :show, id)

      conn = get conn, fuel_path(conn, :show, id)
      assert html_response(conn, 200) =~ "Show Fuel"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post conn, fuel_path(conn, :create), fuel: @invalid_attrs
      assert html_response(conn, 200) =~ "New Fuel"
    end
  end

  describe "edit fuel" do
    setup [:create_fuel]

    test "renders form for editing chosen fuel", %{conn: conn, fuel: fuel} do
      conn = get conn, fuel_path(conn, :edit, fuel)
      assert html_response(conn, 200) =~ "Edit Fuel"
    end
  end

  describe "update fuel" do
    setup [:create_fuel]

    test "redirects when data is valid", %{conn: conn, fuel: fuel} do
      conn = put conn, fuel_path(conn, :update, fuel), fuel: @update_attrs
      assert redirected_to(conn) == fuel_path(conn, :show, fuel)

      conn = get conn, fuel_path(conn, :show, fuel)
      assert html_response(conn, 200) =~ "some updated name"
    end

    test "renders errors when data is invalid", %{conn: conn, fuel: fuel} do
      conn = put conn, fuel_path(conn, :update, fuel), fuel: @invalid_attrs
      assert html_response(conn, 200) =~ "Edit Fuel"
    end
  end

  describe "delete fuel" do
    setup [:create_fuel]

    test "deletes chosen fuel", %{conn: conn, fuel: fuel} do
      conn = delete conn, fuel_path(conn, :delete, fuel)
      assert redirected_to(conn) == fuel_path(conn, :index)
      assert_error_sent 404, fn ->
        get conn, fuel_path(conn, :show, fuel)
      end
    end
  end

  defp create_fuel(_) do
    fuel = fixture(:fuel)
    {:ok, fuel: fuel}
  end
end
