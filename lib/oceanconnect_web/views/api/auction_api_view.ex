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
    %{
      id: auction.id,
      port: auction.port,
      vessel: auction.vessel,
      fuel: auction.fuel,
      buyer: auction.buyer,
      fuel_quantity: auction.fuel_quantity,
      po: auction.po,
      eta: auction.eta,
      etd: auction.etd,
      auction_start: auction.auction_start,
      duration: display_as_minutes(auction.duration),
      decision_duration: display_as_minutes(auction.decision_duration),
      anonymous_bidding: auction.anonymous_bidding,
      additional_information: auction.additional_information,
      suppliers: auction.suppliers,
      state: state
    }
  end

  defp display_as_minutes(duration), do: round(duration / 60_000)
end
