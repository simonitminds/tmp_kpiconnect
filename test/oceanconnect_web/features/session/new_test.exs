defmodule OceanconnectWeb.Session.NewTest do
  use Oceanconnect.FeatureCase
  alias Oceanconnect.AuctionIndexPage
  alias Oceanconnect.Session.{NewPage, ForgotPasswordPage}

  hound_session()

  setup do
    user = insert(:user, password: "password")
    {:ok, %{user: user}}
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
end
