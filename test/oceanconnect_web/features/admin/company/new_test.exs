defmodule Oceanconnect.Admin.Company.NewTest do
  use Oceanconnect.FeatureCase
  alias Oceanconnect.Admin.Company.{IndexPage, EditPage, NewPage}

  hound_session()

  setup do
    admin_user = insert(:user, is_admin: true)
    user = insert(:user, is_admin: false)
    login_user(admin_user)
    {:ok, %{admin_user: admin_user, user: user}}
  end

  describe "creating companies" do
    test "visiting the admin new company page" do
      NewPage.visit()

      assert EditPage.has_fields?([
               "name",
               "address1",
               "address2",
               "city",
               "country",
               "postal_code",
               "contact_name",
               "main_phone",
               "mobile_phone",
               "is_supplier"
             ])
    end

    test "normal users cannot visit admin new company page", %{user: user} do
      login_user(user)
      NewPage.visit()
      refute NewPage.is_current_path?()
    end

    test "admin can create a new company" do
      NewPage.visit()
      EditPage.fill_form(%{name: "some new name"})
      EditPage.submit()
      assert IndexPage.is_current_path?()
      assert IndexPage.company_created_successfully?()
    end
  end
end
