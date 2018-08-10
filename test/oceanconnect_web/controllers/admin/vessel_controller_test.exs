defmodule OceanconnectWeb.Admin.VesselControllerTest do
	use OceanconnectWeb.ConnCase

	alias Oceanconnect.Auctions

  @update_attrs %{imo: 42, name: "some updated name"}
  @invalid_attrs %{imo: nil, name: nil}


  setup do
    user = insert(:user, password: "password", is_admin: "true")
		vessel = insert(:vessel)
		|> Oceanconnect.Repo.preload(:company)
    conn = build_conn()
    |> login_user(user)

    {:ok, %{conn: conn, vessel: vessel}}
  end

  describe "index" do
    test "lists paginated vessels", %{conn: conn} do
      conn = get conn, admin_vessel_path(conn, :index)
      assert html_response(conn, 200) =~ "Vessels"
			assert conn.assigns.page_size == 10
    end
  end

  describe "new vessel" do
    test "renders form", %{conn: conn} do
      conn = get conn, admin_vessel_path(conn, :new)
      assert html_response(conn, 200) =~ "New Vessel"
    end
  end

  describe "create vessel" do
    test "redirects to index when data is valid", %{conn: conn, vessel: vessel} do
			vessel_params = string_params_for(:vessel, company_id: vessel.company_id)
      conn = post conn, admin_vessel_path(conn, :create), vessel: vessel_params

      assert redirected_to(conn) == admin_vessel_path(conn, :index)

      conn = get conn, admin_vessel_path(conn, :index)
      assert html_response(conn, 200) =~ "Vessels"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post conn, admin_vessel_path(conn, :create), vessel: @invalid_attrs
      assert html_response(conn, 200) =~ "New Vessel"
    end
  end

  describe "edit vessel" do
    test "renders form for editing chosen vessel", %{conn: conn, vessel: vessel} do
      conn = get conn, admin_vessel_path(conn, :edit, vessel)
      assert html_response(conn, 200) =~ "Edit Vessel"
    end
  end

  describe "update vessel" do
    test "redirects to index when data is valid", %{conn: conn, vessel: vessel} do
      conn = put conn, admin_vessel_path(conn, :update, vessel), vessel: @update_attrs
      assert redirected_to(conn) == admin_vessel_path(conn, :index)

      conn = get conn, admin_vessel_path(conn, :index)
      assert html_response(conn, 200) =~ "some updated name"
    end

    test "renders errors when data is invalid", %{conn: conn, vessel: vessel} do
      conn = put conn, admin_vessel_path(conn, :update, vessel), vessel: @invalid_attrs
      assert html_response(conn, 200) =~ "Edit Vessel"
    end
  end

  describe "delete vessel" do
    test "deletes chosen vessel", %{conn: conn, vessel: vessel} do
      conn = delete conn, admin_vessel_path(conn, :delete, vessel)
      assert redirected_to(conn) == admin_vessel_path(conn, :index)
			assert_error_sent 404, fn ->
				get conn, admin_vessel_path(conn, :edit, vessel)
			end
		end
  end

	describe "deactivate vessel" do
		test "deactivates chosen vessel", %{conn: conn, vessel: vessel} do
			conn = post conn, admin_vessel_path(conn, :deactivate, vessel)
			assert redirected_to(conn) == admin_vessel_path(conn, :index)
			vessel = Auctions.get_vessel!(vessel.id)
			assert vessel.is_active == false
		end
	end

	describe "activate vessel" do
		test "activates chosen vessel", %{conn: conn, vessel: vessel} do
			conn = post conn, admin_vessel_path(conn, :activate, vessel)
			assert redirected_to(conn) == admin_vessel_path(conn, :index)
			vessel = Auctions.get_vessel!(vessel.id)
			assert vessel.is_active == true
		end
	end
end
