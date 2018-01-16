defmodule Oceanconnect.AuctionNewTest do
  use Oceanconnect.FeatureCase, async: true
  alias Oceanconnect.AuctionNewPage

  hound_session()

  setup do
    user = insert(:user)
    login_user(user)
    {:ok, %{}}
  end

  test "visting the new auction page" do
    AuctionNewPage.visit()

    assert AuctionNewPage.has_fields?([
      "additional_information",
      "anonymous_bidding",
      "auction_start",
      "duration",
      "eta",
      "etd",
      "fuel",
      "fuel_quantity",
      "po",
      "port",
      "vessel"
    ])
  end
end
