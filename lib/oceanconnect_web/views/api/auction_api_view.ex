defmodule OceanconnectWeb.Api.AuctionView do
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

  def render("show.json", %{data: auction_payload}) do
    %{data: render(__MODULE__, "auction.json", data: auction_payload)}
  end

  def render("show.json", %{success: success, message: message}) do
    %{success: success, message: message}
  end

  def render("auction.json", %{data: auction_payload}) do
    AuctionPayload.json_from_payload(auction_payload)
  end
end
