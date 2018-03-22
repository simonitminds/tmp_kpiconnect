defmodule OceanconnectWeb.Api.AuctionView do
  use OceanconnectWeb, :view

  def render("index.json", %{data: auction_payloads}) do
    %{data: Enum.map(auction_payloads, fn(auction_payload) ->
        render(__MODULE__, "auction.json", data: auction_payload)
      end)
    }
  end

  def render("auction.json", %{data: auction_payload}) do
    %{
      time_remaining: auction_payload.time_remaining,
      current_server_time: auction_payload.current_server_time,
      auction: auction_payload.auction,
      state: auction_payload.state,
      bid_list: auction_payload.bid_list
    }
  end
end
