defmodule OceanconnectWeb.Session.NewTest do
  use Oceanconnect.FeatureCase
  alias Oceanconnect.AuctionIndexPage
  alias Oceanconnect.Session.{NewPage, ForgotPasswordPage, TwoFactorAuthPage}

  hound_session()

  setup do
    user = insert(:user, password: "password")
    user_2fa = insert(:user, password: "password", has_2fa: true)

    {:ok, %{user: user, user_2fa: user_2fa}}
  end

  test "logging in with valid user credentials", %{user: user} do
    NewPage.visit()
    NewPage.enter_credentials(user.email, "password")
    NewPage.submit()

    assert AuctionIndexPage.is_current_path?()
  end

  test "user can click the forgot password link and be redirected to that page" do
    NewPage.visit()
    NewPage.forgot_password()

    assert ForgotPasswordPage.is_current_path?()
  end

  test "a user with 2fa enabled logs in and is redirected to the two factor auth page", %{user_2fa: user_2fa} do
    NewPage.visit()
    NewPage.enter_credentials(user_2fa.email, "password")
    NewPage.submit()

    assert TwoFactorAuthPage.is_current_path?()
  end
end
