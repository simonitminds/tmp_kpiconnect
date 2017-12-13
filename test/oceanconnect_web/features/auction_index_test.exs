defmodule Oceanconnect.AuctionIndexTest do
  use Oceanconnect.FeatureCase, async: true
  alias Oceanconnect.AuctionIndex

  # setup do
  #   {:ok, %{conn: build_conn()}}
  # end

  test "renders the default auction index page", %{session: session} do
    session
    |> AuctionIndex.visit()

    assert AuctionIndex.has_content?(session, "Listing Auctions")
  end
end
