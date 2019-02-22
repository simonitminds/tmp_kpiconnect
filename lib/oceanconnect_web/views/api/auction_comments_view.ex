defmodule OceanconnectWeb.Api.AuctionCommentsView do
  use OceanconnectWeb, :view

  alias Oceanconnect.Auctions.AuctionPayload

  def render("submit.json", %{auction_payload: auction_payload}) do
    AuctionPayload.json_from_payload(auction_payload)
  end

  def render("show.json", %{success: success, message: message}) do
    %{success: success, message: message}
  end
end
