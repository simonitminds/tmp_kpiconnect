defmodule Oceanconnect.AuctionIndexTest do
  use Oceanconnect.FeatureCase, async: true
  alias Oceanconnect.AuctionIndex

  setup(%{session: session}) do
    user = insert(:user)
    login_user(session, user)
    {:ok}
  end

  test "renders the default auction index page", %{session: session} do
    session
    |> AuctionIndex.visit()

    assert AuctionIndex.has_content?(session, "Auction Listing")

  end
end
