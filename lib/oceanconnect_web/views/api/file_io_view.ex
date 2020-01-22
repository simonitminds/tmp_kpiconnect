defmodule OceanconnectWeb.Api.FileIOView do
  use OceanconnectWeb, :view

  alias Oceanconnect.Auctions.AuctionPayload

  def render("show.json", %{success: success, message: message}) do
    %{success: success, message: message}
  end

  def render("show_coq.json", %{coq: coq}) do
    %{coq: coq}
  end

  def render("submit.json", %{auction_payload: auction_payload}) do
    AuctionPayload.json_from_payload(auction_payload)
  end
end
