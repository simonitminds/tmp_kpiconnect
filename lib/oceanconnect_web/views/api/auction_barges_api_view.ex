defmodule OceanconnectWeb.Api.AuctionBargesView do
  use OceanconnectWeb, :view

  def render("submit.json", %{auction_payload: auction_payload}) do
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

  def render("show.json", %{success: success, message: message}) do
    %{success: success, message: message}
  end
end
