defmodule OceanconnectWeb.SessionTest do
  use Oceanconnect.FeatureCase, async: true
  alias Oceanconnect.{AuctionIndex, NewSessionPage}

  setup do
    user = insert(:user, password: "password")
    {:ok, %{user: user}}
  end

  test "logging in with valid user credentials", %{session: session, user: user} do
    NewSessionPage.visit(session)
    NewSessionPage.enter_credentials(session, user.email, "password")
    NewSessionPage.submit(session)

    assert AuctionIndex.is_current_path?(session)
  end
end
