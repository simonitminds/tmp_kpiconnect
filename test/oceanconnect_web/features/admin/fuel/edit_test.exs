defmodule Oceanconnect.Admin.Fuel.EditTest do
  use Oceanconnect.FeatureCase
  alias Oceanconnect.Admin.Fuel.{IndexPage, EditPage}

  hound_session()

  setup do
    admin_user = insert(:user, is_admin: true)
    user = insert(:user, is_admin: false)
    fuel = insert(:fuel)
    login_user(admin_user)
    {:ok, %{admin_user: admin_user, fuel: fuel, user: user}}
  end

  describe "editing fuels" do
    test "visiting the admin edit fuel page", %{fuel: fuel} do
      EditPage.visit(fuel.id)

      assert EditPage.has_fields?([
               "name"
             ])
    end

    test "normal users cannot visit admin edit fuel page", %{user: user, fuel: fuel} do
      login_user(user)
      EditPage.visit(fuel.id)
      refute EditPage.is_current_path?(fuel.id)
    end

    test "admin can edit a fuel and submit the changes", %{fuel: fuel} do
      EditPage.visit(fuel.id)
      EditPage.fill_form(%{name: "some new name"})
      EditPage.submit()
      assert IndexPage.is_current_path?()
      assert IndexPage.has_fuel_name?("some new name")
    end

    test "admin can delete a fuel", %{fuel: fuel} do
      EditPage.visit(fuel.id)
      EditPage.delete()
      assert IndexPage.is_current_path?()
      refute IndexPage.has_fuel?(fuel.id)
    end
  end
end
