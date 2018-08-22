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
      status: auction_payload.status,
      winning_bid: auction_payload.winning_bid,
      lowest_bids: auction_payload.lowest_bids,
      bid_history: auction_payload.bid_history,
      is_leading: auction_payload.is_leading,
      lead_is_tied: auction_payload.lead_is_tied,
      submitted_barges: auction_payload.submitted_barges
    }
  end
end
