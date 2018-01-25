defmodule Oceanconnect.AuctionIndexTest do
  use Oceanconnect.FeatureCase, async: true
  alias Oceanconnect.AuctionIndexPage

  hound_session()

  setup do
    user = insert(:user)
    login_user(user)
    auctions = insert_list(2, :auction)
    {:ok, %{auctions: auctions}}
  end

  test "renders the default auction index page", %{auctions: auctions} do
    AuctionIndexPage.visit()

    assert AuctionIndexPage.is_current_path?()
    assert AuctionIndexPage.has_auctions?(auctions)
  end
end
