defmodule OceanconnectWeb.Admin.FuelIndex.EditTest do
  use Oceanconnect.FeatureCase
  alias Oceanconnect.Admin.FuelIndex.{IndexPage, EditPage}

  hound_session()

  setup do
    admin_user = insert(:user, is_admin: true)
    user = insert(:user, is_admin: false)
    fuel_index = insert(:fuel_index)
    fuel = insert(:fuel)
    port = insert(:port)

    login_user(admin_user)
    {:ok, %{admin_user: admin_user, fuel_index: fuel_index, user: user, fuel: fuel, port: port}}
  end

  describe "editing fuel index entries" do
    test "visiting the admin edit fuel index page", %{fuel_index: fuel_index} do
      EditPage.visit(fuel_index.id)

      assert EditPage.is_current_path?(fuel_index.id)
      assert EditPage.has_fields?([
        "code",
        "name",
        "fuel_id",
        "port_id"
      ])
    end

    test "normal users cannot visit admin edit fuel_index page", %{user: user, fuel_index: fuel_index} do
      login_user(user)
      EditPage.visit(fuel_index.id)
      refute EditPage.is_current_path?(fuel_index.id)
    end

    test "admin can edit a fuel_index and submit the changes", %{fuel_index: fuel_index, fuel: fuel, port: port} do
      EditPage.visit(fuel_index.id)

      EditPage.fill_form(%{
        name: "some new name",
        code: fuel_index.code,
        port_id: port.id,
        fuel_id: fuel.id
      })

      EditPage.submit()
      assert IndexPage.is_current_path?()
      assert IndexPage.has_fuel_index_name?("some new name")
    end

    test "admin can delete a fuel_index", %{fuel_index: fuel_index} do
      EditPage.visit(fuel_index.id)
      EditPage.delete()
      assert IndexPage.is_current_path?()
      refute IndexPage.has_fuel_index?(fuel_index.id)
    end
  end
end
