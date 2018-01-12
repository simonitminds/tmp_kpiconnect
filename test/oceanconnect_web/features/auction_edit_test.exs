defmodule Oceanconnect.AuctionEditTest do
  use Oceanconnect.FeatureCase, async: true
  alias Oceanconnect.AuctionEditPage

  setup(%{session: session}) do
    user = insert(:user)
    login_user(session, user)
    {:ok, %{auction: insert(:auction)}}
  end

  test "visting the edit auction page", %{session: session, auction: auction} do
    session
    |> AuctionEditPage.visit(auction.id)

    assert AuctionEditPage.has_fields?(session, [
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
