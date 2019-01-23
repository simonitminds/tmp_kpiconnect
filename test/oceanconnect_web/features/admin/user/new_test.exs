defmodule Oceanconnect.Admin.User.NewTest do
  use Oceanconnect.FeatureCase
  alias Oceanconnect.Admin.User.{IndexPage, EditPage, NewPage}

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
               "email",
               "first_name",
               "last_name",
               "is_admin",
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

      EditPage.fill_form(%{
        email: "NEW@EMAIL.COM",
        first_name: "new",
        last_name: "name",
        company_id: company.id
      })

      EditPage.submit()
      assert IndexPage.is_current_path?()
      assert IndexPage.user_created_successfully?()
    end
  end
end
