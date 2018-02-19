defmodule OceanconnectWeb.Api.AuctionView do
  use OceanconnectWeb, :view

  def render("index.json", %{data: auctions}) do
    %{data: Enum.map(auctions, fn(auction) ->
        render(__MODULE__, "auction.json", data: auction)
      end)
    }
  end

  def render("auction.json", %{data: auction}) do
    state = case Oceanconnect.Auctions.auction_state(auction) do
      %{state: state} -> state
      _ -> nil
    end
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
