defmodule Oceanconnect.Admin.Port.NewTest do
  use Oceanconnect.FeatureCase
  alias Oceanconnect.Admin.Port.{IndexPage, EditPage, NewPage}

  hound_session()

  setup do
    admin_user = insert(:user, is_admin: true)
    user = insert(:user, is_admin: false)
    companies = insert_list(2, :company)
    login_user(admin_user)
    {:ok, %{admin_user: admin_user, user: user, companies: companies}}
  end

  describe "creating ports" do
    test "visiting the admin new user port" do
      NewPage.visit()
      assert NewPage.is_current_path?()

      assert EditPage.has_fields?([
               "name",
               "country",
               "companies"
             ])
    end

    test "normal users cannot visit admin new port page", %{user: user} do
      login_user(user)
      NewPage.visit()
      refute NewPage.is_current_path?()
    end

    test "admin can create a new port", %{companies: companies} do
      NewPage.visit()
      EditPage.fill_form(%{name: "some new name", country: "Murricah", companies: companies})
      EditPage.submit()
      assert IndexPage.is_current_path?()
      assert IndexPage.has_port_name?("some new name")
    end
  end
end
