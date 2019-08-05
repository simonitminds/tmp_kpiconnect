defmodule OceanconnectWeb.Api.ObserverView do
  use OceanconnectWeb, :view

  alias Oceanconnect.Auctions.AuctionPayload

  def render("invite.json", %{auction_payload: auction_payload}) do
    AuctionPayload.json_from_payload(auction_payload)
  end

  def render("show,json", response) do
    response
  end
end
