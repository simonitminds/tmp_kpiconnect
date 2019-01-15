defmodule Oceanconnect.Admin.User.EditTest do
  use Oceanconnect.FeatureCase
  alias Oceanconnect.Admin.User.{IndexPage, EditPage}

  hound_session()

  setup do
    admin_user = insert(:user, is_admin: true)
    user = insert(:user, is_admin: false)
    company = insert(:company)
    login_user(admin_user)
    {:ok, %{admin_user: admin_user, user: user, company: company}}
  end

  describe "editing users" do
    test "visiting the admin edit user page", %{user: user} do
      EditPage.visit(user.id)

      assert EditPage.has_fields?([
               "email",
               "first_name",
               "last_name",
               "has_2fa",
               "is_admin"
             ])
    end

    test "normal users cannot visit admin edit user page", %{user: user} do
      login_user(user)
      EditPage.visit(user.id)
      refute EditPage.is_current_path?(user.id)
    end

    test "admin can edit a user and submit the changes", %{user: user, company: company} do
      EditPage.visit(user.id)

      EditPage.fill_form(%{
        email: user.email,
        first_name: "new",
        last_name: "name",
        company_id: company.id
      })

      EditPage.submit()
      assert IndexPage.is_current_path?()
      assert IndexPage.has_user_name?("new name", user.id)
    end

    test "admin can delete a user", %{user: user} do
      EditPage.visit(user.id)
      EditPage.delete()
      assert IndexPage.is_current_path?()
      refute IndexPage.has_user?(user.id)
    end

    test "admin can send a password reset email to a user", %{user: user} do
      EditPage.visit(user.id)
      assert EditPage.is_current_path?(user.id)
      EditPage.send_password_reset_email()
      assert EditPage.has_content?("An email has been sent to the user with instructions to reset their password")
    end
  end
end
