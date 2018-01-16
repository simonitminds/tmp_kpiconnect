defmodule OceanconnectWeb.VesselControllerTest do
  use OceanconnectWeb.ConnCase

  setup do
    user = insert(:user, password: "password")
    vessel = insert(:vessel)
    |> Oceanconnect.Repo.preload(:company)
    conn = build_conn()
    |> login_user(user)

    {:ok, %{conn: conn, vessel: vessel}}
  end

  describe "index" do
    test "lists all vessels", %{conn: conn} do
      conn = get conn, vessel_path(conn, :index)
      assert html_response(conn, 200) =~ "Listing Vessels"
    end
  end

  describe "new vessel" do
    test "renders form", %{conn: conn} do
      conn = get conn, vessel_path(conn, :new)
      assert html_response(conn, 200) =~ "New Vessel"
    end
  end

  describe "create vessel" do
    test "redirects to show when data is valid", %{conn: conn, vessel: vessel} do
      vessel_params = string_params_for(:vessel, company_id: vessel.company_id)
      conn = post(conn, vessel_path(conn, :create), vessel: vessel_params)
      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == vessel_path(conn, :show, id)

      conn = get conn, vessel_path(conn, :show, id)
      assert html_response(conn, 200) =~ "Show Vessel"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post conn, vessel_path(conn, :create), vessel: %{imo: nil, name: nil}
      assert html_response(conn, 200) =~ "New Vessel"
    end
  end

  describe "edit vessel" do
    test "renders form for editing chosen vessel", %{conn: conn, vessel: vessel} do
      conn = get conn, vessel_path(conn, :edit, vessel)
      assert html_response(conn, 200) =~ "Edit Vessel"
    end
  end

  describe "update vessel" do
    test "redirects when data is valid", %{conn: conn, vessel: vessel} do
      conn = put conn, vessel_path(conn, :update, vessel), vessel: %{imo: 43, name: "some updated name"}
      assert redirected_to(conn) == vessel_path(conn, :show, vessel)

      conn = get conn, vessel_path(conn, :show, vessel)
      assert html_response(conn, 200) =~ "some updated name"
    end

    test "renders errors when data is invalid", %{conn: conn, vessel: vessel} do
      conn = put conn, vessel_path(conn, :update, vessel), vessel: %{imo: nil, name: nil}
      assert html_response(conn, 200) =~ "Edit Vessel"
    end
  end

  describe "delete vessel" do
    test "deletes chosen vessel", %{conn: conn, vessel: vessel} do
      conn = delete conn, vessel_path(conn, :delete, vessel)
      assert redirected_to(conn) == vessel_path(conn, :index)
      assert_error_sent 404, fn ->
        get conn, vessel_path(conn, :show, vessel)
      end
    end
  end
end
