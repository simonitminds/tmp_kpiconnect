defmodule OceanconnectWeb.Session.ForgotPasswordTest do
  use Oceanconnect.FeatureCase
  alias Oceanconnect.Session.{NewPage, ForgotPasswordPage}

  hound_session()

  setup do
    user = insert(:user)
    {:ok, %{user: user}}
  end

  test "submitting a valid email address", %{user: user} do
    ForgotPasswordPage.visit()
    ForgotPasswordPage.enter_email(user.email)
    ForgotPasswordPage.submit()

    assert NewPage.is_current_path?()
    assert NewPage.inner_html =~ "An email has been sent with instructions to reset your password"
  end

  test "submitting an invalid email address" do
    ForgotPasswordPage.visit()
    ForgotPasswordPage.enter_email("invalid-email@example.com")
    ForgotPasswordPage.submit()

    assert ForgotPasswordPage.is_current_path?()
    assert ForgotPasswordPage.inner_html() =~ "That email address does not exist in the system"
  end
end
