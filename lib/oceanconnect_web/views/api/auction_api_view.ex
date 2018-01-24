defmodule OceanconnectWeb.Api.AuctionApiView do
  use OceanconnectWeb, :view

  def render("index.json", %{auctions: auctions}) do
    %{data: Enum.map(auctions, fn(auction) ->
        render(__MODULE__, "auction.json", auction: auction)
      end)
    }
  end

  def render("auction.json", %{auction: auction}) do
    Map.put(auction, :status, OceanconnectWeb.AuctionView.auction_status(auction))
  end
end
