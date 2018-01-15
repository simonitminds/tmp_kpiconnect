defmodule OceanconnectWeb.SessionTest do
  use Oceanconnect.FeatureCase, async: true
  alias Oceanconnect.{AuctionIndex, NewSessionPage}

  hound_session()

  setup do
    user = insert(:user, password: "password")
    {:ok, %{user: user}}
  end

  test "logging in with valid user credentials", %{user: user} do
    NewSessionPage.visit()
    NewSessionPage.enter_credentials(user.email, "password")
    NewSessionPage.submit()

    assert AuctionIndex.is_current_path?()
  end
end
