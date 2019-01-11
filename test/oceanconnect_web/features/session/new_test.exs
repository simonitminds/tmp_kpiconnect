defmodule OceanconnectWeb.Session.NewTest do
  use Oceanconnect.FeatureCase
  alias Oceanconnect.AuctionIndexPage
  alias Oceanconnect.Session.{NewPage, ForgotPasswordPage}

  hound_session()

  setup do
    user = insert(:user, password: "password", has_2fa: true)
    user_2fa = insert(:user, password: "password", has_2fa: true)
    secret =
      :crypt.strong_rand_bytes(8)
      |> Base.encode32()

    token = :pot.hotp(secret, _num_of_trials = 1)

    {:ok, %{user: user, user_2fa: user_2fa, token: token, secret: secret}}
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

  test "a user with 2fa enabled logs in with both their password and a 2fa token", %{user_2fa: user_2fa, token: token, secret: secret} do
    NewPage.visit()
    NewPage.enter_credentials(user_2fa.email, "password")
    NewPage.submit()

    assert TwoFactorAuthPage.is_current_path?()
    TwoFactorAuthPage.enter_credentials(token, secret)

    assert AuctionIndexPage.is_current_path?()
  end
end
