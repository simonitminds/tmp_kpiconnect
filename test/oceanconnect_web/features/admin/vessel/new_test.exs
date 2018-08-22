defmodule Oceanconnect.Admin.Vessel.NewTest do
  use Oceanconnect.FeatureCase
  alias Oceanconnect.Admin.Vessel.{IndexPage, EditPage, NewPage}

  hound_session()

  setup do
    admin_user = insert(:user, is_admin: true)
    user = insert(:user, is_admin: false)
    company = insert(:company)
    login_user(admin_user)
    {:ok, %{admin_user: admin_user, user: user, company: company}}
  end

  describe "creating users" do
    test "visiting the admin new user page" do
      NewPage.visit()

      assert EditPage.has_fields?([
               "imo",
               "name",
               "company_id"
             ])
    end

    test "normal users cannot visit admin new user page", %{user: user} do
      login_user(user)
      NewPage.visit()
      refute NewPage.is_current_path?()
    end

    test "admin can create a new user", %{company: company} do
      NewPage.visit()
      EditPage.fill_form(%{imo: 1_234_567, name: "some new name", company_id: company.id})
      EditPage.submit()
      assert IndexPage.is_current_path?()
      assert IndexPage.has_vessel_name?("some new name")
    end
  end
end
