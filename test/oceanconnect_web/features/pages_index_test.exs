defmodule Oceanconnect.IndexTest do
  use Oceanconnect.FeatureCase, async: true
  alias Oceanconnect.IndexPage

  setup(%{session: session}) do
    user = insert(:user)
    login_user(session, user)
    {:ok, %{auction: insert(:auction)}}
  end

  test "renders the default index page", %{session: session} do
    session
    |> IndexPage.visit()

    assert IndexPage.has_title?(session, "Hello Oceanconnect!")
  end
end
