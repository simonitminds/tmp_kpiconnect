defmodule OceanconnectWeb.Admin.PortControllerTest do
	use OceanconnectWeb.ConnCase

	alias Oceanconnect.Auctions

  @create_attrs %{name: "some name", country: "Merica"}
  @update_attrs %{name: "some updated name", country: "Merica"}
  @invalid_attrs %{name: nil, country: "Merica"}

  def fixture(:port) do
    {:ok, port} = Auctions.create_port(@create_attrs)
    port
  end

  setup do
    user = insert(:user, password: "password", is_admin: "true")
    conn = build_conn()
    |> login_user(user)
    {:ok, %{conn: conn}}
  end

  describe "index" do
    test "lists paginated ports", %{conn: conn} do
      conn = get conn, admin_port_path(conn, :index)
      assert html_response(conn, 200) =~ "Ports"
			assert conn.assigns.page_size == 10
    end
  end

  describe "new port" do
    test "renders form", %{conn: conn} do
      conn = get conn, admin_port_path(conn, :new)
      assert html_response(conn, 200) =~ "New Port"
    end
  end

  describe "create port" do
    test "redirects to index when data is valid", %{conn: conn} do
      conn = post conn, admin_port_path(conn, :create), port: @create_attrs

      assert redirected_to(conn) == admin_port_path(conn, :index)

      conn = get conn, admin_port_path(conn, :index)
      assert html_response(conn, 200) =~ "Ports"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post conn, admin_port_path(conn, :create), port: @invalid_attrs
      assert html_response(conn, 200) =~ "New Port"
    end
  end

  describe "edit port" do
    setup [:create_port]

    test "renders form for editing chosen port", %{conn: conn, port: port} do
      conn = get conn, admin_port_path(conn, :edit, port)
      assert html_response(conn, 200) =~ "Edit Port"
    end
  end

  describe "update port" do
    setup [:create_port]

    test "redirects to index when data is valid", %{conn: conn, port: port} do
      conn = put conn, admin_port_path(conn, :update, port), port: @update_attrs
      assert redirected_to(conn) == admin_port_path(conn, :index)

      conn = get conn, admin_port_path(conn, :index)
      assert html_response(conn, 200) =~ "some updated name"
    end

    test "renders errors when data is invalid", %{conn: conn, port: port} do
      conn = put conn, admin_port_path(conn, :update, port), port: @invalid_attrs
      assert html_response(conn, 200) =~ "Edit Port"
    end
  end

  describe "delete port" do
    setup [:create_port]

    test "deletes chosen port", %{conn: conn, port: port} do
      conn = delete conn, admin_port_path(conn, :delete, port)
      assert redirected_to(conn) == admin_port_path(conn, :index)
      assert port.is_active == false
		end
  end

  defp create_port(_) do
    port = fixture(:port)
    {:ok, port: port}
  end
end
