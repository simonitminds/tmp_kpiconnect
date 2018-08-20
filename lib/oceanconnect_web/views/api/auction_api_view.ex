defmodule OceanconnectWeb.Api.AuctionView do
  use OceanconnectWeb, :view

  def render("index.json", %{data: auction_payloads}) do
    %{
      data:
        Enum.map(auction_payloads, fn auction_payload ->
          render(__MODULE__, "auction.json", data: auction_payload)
        end)
    }
  end

  def render("auction.json", %{data: auction_payload}) do
    %{
      time_remaining: auction_payload.time_remaining,
      current_server_time: auction_payload.current_server_time,
      auction: auction_payload.auction,
      bid_history: auction_payload.bid_history,
      status: auction_payload.status,
      product_bids: auction_payload.product_bids,
      solutions: auction_payload.solutions,
      submitted_barges: auction_payload.submitted_barges
    }
  end
end
