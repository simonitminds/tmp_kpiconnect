defmodule OceanconnectWeb.Api.AuctionApiView do
  use OceanconnectWeb, :view

  def render("index.json", %{auctions: auctions}) do
    %{data: Enum.map(auctions, fn(auction) ->
        render(__MODULE__, "auction.json", auction: auction)
      end)
    }
  end

  def render("auction.json", %{auction: auction}) do
    %{state: state} = Oceanconnect.Auctions.auction_state(auction)
    Map.put(auction, :state, state)
  end
end
