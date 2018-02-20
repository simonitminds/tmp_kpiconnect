defmodule OceanconnectWeb.SessionTest do
  use Oceanconnect.FeatureCase, async: false
  alias Oceanconnect.{AuctionIndexPage, NewSessionPage}

  hound_session()

  setup do
    user = insert(:user, password: "password")
    {:ok, %{user: user}}
  end

  test "logging in with valid user credentials", %{user: user} do
    NewSessionPage.visit()
    NewSessionPage.enter_credentials(user.email, "password")
    NewSessionPage.submit()

    assert AuctionIndexPage.is_current_path?()
  end
end
