defmodule Oceanconnect.Admin.FuelIndex.NewTest do
  use Oceanconnect.FeatureCase
  alias Oceanconnect.Admin.FuelIndex.{IndexPage, EditPage, NewPage}

  hound_session()

  setup do
    admin_user = insert(:user, is_admin: true)
    user = insert(:user, is_admin: false)
    port = insert(:port)
    fuel = insert(:fuel)

    login_user(admin_user)
    {:ok, %{admin_user: admin_user, user: user, port: port, fuel: fuel}}
  end

  describe "creating fuel indexes" do
    test "visiting the admin new fuel index page" do
      NewPage.visit()

      assert NewPage.is_current_path?()
      assert EditPage.has_fields?([
        "code",
        "name",
        "fuel_id",
        "port_id"
      ])
    end

    test "normal users cannot visit admin new fuel index page", %{user: user} do
      login_user(user)
      NewPage.visit()

      refute NewPage.is_current_path?()
    end

    test "admin can create a new fuel index", %{port: port, fuel: fuel} do
      NewPage.visit()

      EditPage.fill_form(%{
        code: "1234",
        name: "some new name",
        fuel_id: fuel.id,
        port_id: port.id
      })

      EditPage.submit()
      assert IndexPage.is_current_path?()
      assert IndexPage.has_fuel_index_name?("some new name")
    end
  end
end
