defmodule Oceanconnect.User.EditTest do
  use Oceanconnect.FeatureCase
  alias Oceanconnect.User.EditPage

  hound_session()

  setup do
    user = insert(:user)
    another_user = insert(:user)
    login_user(user)
    {:ok, %{user: user, another_user: another_user}}
  end

  describe "editing users" do
    test "visiting the edit user page", %{user: user} do
      EditPage.visit(user.id)

      assert EditPage.has_fields?([
               "email",
               "first_name",
               "last_name",
               "office_phone",
               "mobile_phone",
               "has_2fa"
             ])
    end

    test "user can edit their information and submit the changes", %{user: user} do
      EditPage.visit(user.id)

      EditPage.fill_form(%{
        email: user.email,
        first_name: "new",
        last_name: "name",
        office_phone: "1234567",
        mobile_phone: "1234567"
      })

      EditPage.submit()
      assert EditPage.is_current_path?(user.id)
    end

    test "a user cannot visit another user's edit page", %{another_user: another_user} do
      EditPage.visit(another_user.id)
      refute EditPage.is_current_path?(another_user.id)
    end

    test "a user that is not logged in cannot visit their edit page", %{user: user} do
      logout_user()
      EditPage.visit(user.id)
      refute EditPage.is_current_path?(user.id)
    end
  end
end
