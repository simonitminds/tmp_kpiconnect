defmodule Oceanconnect.AuctionIndexTest do
  use Oceanconnect.FeatureCase, async: true
  alias Oceanconnect.AuctionIndexPage

  hound_session()

  setup do
    user = insert(:user)
    login_user(user)
    {:ok, %{}}
  end

  test "renders the default auction index page" do
    AuctionIndexPage.visit()

    assert AuctionIndexPage.has_content?("Auction Listing")
  end
end
