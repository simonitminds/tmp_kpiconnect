defmodule Oceanconnect.Notifications.Emails.PasswordResetTest do
  use Oceanconnect.DataCase
  alias Oceanconnect.Notifications.Emails.PasswordReset

  describe "password reset emails" do
    setup do
      user = insert(:user)

      {:ok, %{user: user}}
    end

    test "password reset email builds for the inputted user", %{user: user} do
      {:ok, token, _claims} = Oceanconnect.Guardian.encode_and_sign(user, %{email: true})
      [password_reset_email] = PasswordReset.generate(user, token)

      assert password_reset_email.to.id == user.id
      assert password_reset_email.assigns.token == token
    end
  end
end
