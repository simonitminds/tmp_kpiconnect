defmodule OceanconnectWeb.PortControllerTest do
  use OceanconnectWeb.ConnCase

  alias Oceanconnect.Auctions

  @create_attrs %{name: "some name"}
  @update_attrs %{name: "some updated name"}
  @invalid_attrs %{name: nil}

  def fixture(:port) do
    {:ok, port} = Auctions.create_port(@create_attrs)
    port
  end

  describe "index" do
    test "lists all ports", %{conn: conn} do
      conn = get conn, port_path(conn, :index)
      assert html_response(conn, 200) =~ "Listing Ports"
    end
  end

  describe "new port" do
    test "renders form", %{conn: conn} do
      conn = get conn, port_path(conn, :new)
      assert html_response(conn, 200) =~ "New Port"
    end
  end

  describe "create port" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post conn, port_path(conn, :create), port: @create_attrs

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == port_path(conn, :show, id)

      conn = get conn, port_path(conn, :show, id)
      assert html_response(conn, 200) =~ "Show Port"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post conn, port_path(conn, :create), port: @invalid_attrs
      assert html_response(conn, 200) =~ "New Port"
    end
  end

  describe "edit port" do
    setup [:create_port]

    test "renders form for editing chosen port", %{conn: conn, port: port} do
      conn = get conn, port_path(conn, :edit, port)
      assert html_response(conn, 200) =~ "Edit Port"
    end
  end

  describe "update port" do
    setup [:create_port]

    test "redirects when data is valid", %{conn: conn, port: port} do
      conn = put conn, port_path(conn, :update, port), port: @update_attrs
      assert redirected_to(conn) == port_path(conn, :show, port)

      conn = get conn, port_path(conn, :show, port)
      assert html_response(conn, 200) =~ "some updated name"
    end

    test "renders errors when data is invalid", %{conn: conn, port: port} do
      conn = put conn, port_path(conn, :update, port), port: @invalid_attrs
      assert html_response(conn, 200) =~ "Edit Port"
    end
  end

  describe "delete port" do
    setup [:create_port]

    test "deletes chosen port", %{conn: conn, port: port} do
      conn = delete conn, port_path(conn, :delete, port)
      assert redirected_to(conn) == port_path(conn, :index)
      assert_error_sent 404, fn ->
        get conn, port_path(conn, :show, port)
      end
    end
  end

  defp create_port(_) do
    port = fixture(:port)
    {:ok, port: port}
  end
end
