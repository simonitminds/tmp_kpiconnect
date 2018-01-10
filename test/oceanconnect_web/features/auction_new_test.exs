defmodule Oceanconnect.AuctionNewTest do
  use Oceanconnect.FeatureCase, async: true
  alias Oceanconnect.AuctionNewPage

  test "visting the new auction page", %{session: session} do
    session
    |> AuctionNewPage.visit()

    assert AuctionNewPage.has_fields?(session, [
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
