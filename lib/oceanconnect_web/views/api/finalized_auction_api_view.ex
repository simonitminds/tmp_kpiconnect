defmodule OceanconnectWeb.Api.FinalizedAuctionView do
  use OceanconnectWeb, :view
  alias Oceanconnect.Auctions.AuctionPayload

  def render("index.json", %{data: auction_payloads}) do
    %{
      data:
        Enum.map(auction_payloads, fn auction_payload ->
          render(__MODULE__, "auction.json", data: auction_payload)
        end)
    }
  end
  def render("auction.json", %{data: auction_payload}) do
   AuctionPayload.json_from_payload(auction_payload)
  end
end
