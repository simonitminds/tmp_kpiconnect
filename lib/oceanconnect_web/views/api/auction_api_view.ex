defmodule OceanconnectWeb.Api.AuctionView do
  use OceanconnectWeb, :view

  def render("index.json", %{data: auction_payloads}) do
    %{data: Enum.map(auction_payloads, fn(auction_payload) ->
        render(__MODULE__, "auction.json", data: auction_payload)
      end)
    }
  end

  def render("auction.json", %{data: auction_payload}) do
    bid_list = case auction_payload do
      %{bid_list: bid_list} -> bid_list
      _ -> []
    end
    %{
      id: auction_payload.id,
      port: auction_payload.port,
      vessel: auction_payload.vessel,
      fuel: auction_payload.fuel,
      buyer: auction_payload.buyer,
      fuel_quantity: auction_payload.fuel_quantity,
      po: auction_payload.po,
      eta: auction_payload.eta,
      etd: auction_payload.etd,
      auction_start: auction_payload.auction_start,
      duration: display_as_minutes(auction_payload.duration),
      decision_duration: display_as_minutes(auction_payload.decision_duration),
      anonymous_bidding: auction_payload.anonymous_bidding,
      additional_information: auction_payload.additional_information,
      suppliers: auction_payload.suppliers,
      state: auction_payload.state,
      bid_list: bid_list
    }
  end

  defp display_as_minutes(duration), do: round(duration / 60_000)
end
