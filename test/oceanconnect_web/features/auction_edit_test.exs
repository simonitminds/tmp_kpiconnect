defmodule Oceanconnect.AuctionEditTest do
  use Oceanconnect.FeatureCase, async: true
  alias Oceanconnect.AuctionEditPage

  hound_session()

  setup do
    user = insert(:user)
    login_user(user)
    {:ok, %{auction: insert(:auction)}}
  end

  test "visting the edit auction page", %{auction: auction} do
    AuctionEditPage.visit(auction.id)

    assert AuctionEditPage.has_fields?([
      "additional_information",
      "anonymous_bidding",
      "auction_start",
      "company",
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
