defmodule OceanconnectWeb.Api.AuctionBargesView do
  use OceanconnectWeb, :view

  def render("submit.json", %{auction_payload: auction_payload}) do
    %{
      time_remaining: auction_payload.time_remaining,
      current_server_time: auction_payload.current_server_time,
      auction: auction_payload.auction,
      status: auction_payload.status,
      submitted_barges: auction_payload.submitted_barges
    }
  end

  def render("show.json", %{success: success, message: message}) do
    %{success: success, message: message}
  end
end
