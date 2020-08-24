defmodule OceanconnectWeb.Session.NewTest do
  use Oceanconnect.FeatureCase
  alias Oceanconnect.AuctionIndexPage
  alias Oceanconnect.Session.{NewPage, ForgotPasswordPage, TwoFactorAuthPage, RegistrationPage}

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

  test "a user with 2fa enabled logs in and is redirected to the two factor auth page", %{
    user_2fa: user_2fa
  } do
    NewPage.visit()
    NewPage.enter_credentials(user_2fa.email, "password")
    NewPage.submit()

    assert TwoFactorAuthPage.is_current_path?()
  end

  test "a user can resend the 2fa email", %{user_2fa: user_2fa} do
    NewPage.visit()
    NewPage.enter_credentials(user_2fa.email, "password")
    NewPage.submit()

    assert TwoFactorAuthPage.is_current_path?()
    TwoFactorAuthPage.resend_2fa_email()

    assert TwoFactorAuthPage.has_content?(
             "A new two-factor authentication code has been sent to your email"
           )
  end

  test "a user can express interest in registering for the application", %{user: user} do
    NewPage.visit()
    NewPage.register()

    assert RegistrationPage.is_current_path?()

    RegistrationPage.enter_credentials(
      user.first_name,
      user.last_name,
      user.company.name,
      user.office_phone,
      user.mobile_phone,
      user.email
    )

    RegistrationPage.submit()

    assert NewPage.is_current_path?()

    assert NewPage.has_content?(
             "Thank you for expressing interest in AuctionConnect. You will be contacted by an auction administrator."
           )
  end
end
