defmodule OceanconnectWeb.Session.ResetPasswordTest do
  use Oceanconnect.FeatureCase
  alias Oceanconnect.Session.{NewPage, ResetPasswordPage}
  alias Oceanconnect.AuctionIndexPage
  alias Oceanconnect.Guardian

  hound_session()

  setup do
    user = insert(:user)
    {:ok, token, _claims} = Guardian.encode_and_sign(user, %{user_id: user.id, email: true})

    {:ok, %{user: user, token: token}}
  end

  test "user can reset there password and log in with new credentials", %{
    user: user,
    token: token
  } do
    ResetPasswordPage.visit(token)
    assert ResetPasswordPage.is_current_path?()
    ResetPasswordPage.enter_credentials("newpass", "newpass")
    ResetPasswordPage.submit()

    assert NewPage.is_current_path?()
    assert NewPage.has_content?("Password updated successfully")
    NewPage.enter_credentials(user.email, "newpass")
    NewPage.submit()
    assert AuctionIndexPage.is_current_path?()
  end
end
