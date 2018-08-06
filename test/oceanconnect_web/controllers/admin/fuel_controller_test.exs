defmodule OceanconnectWeb.Admin.FuelControllerTest do
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
    test "lists paginated fuels", %{conn: conn} do
      conn = get conn, admin_fuel_path(conn, :index)
      assert html_response(conn, 200) =~ "Fuel Grades"
			assert conn.assigns.page_size == 10
    end
  end

end
