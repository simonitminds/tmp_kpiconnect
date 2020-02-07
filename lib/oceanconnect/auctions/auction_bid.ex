defmodule Oceanconnect.Auctions.AuctionBid do
  import Oceanconnect.Auctions.Guards

  @enforce_keys [:auction_id, :amount, :supplier_id, :vessel_fuel_id]
  defstruct id: nil,
            auction_id: nil,
            supplier_id: nil,
            vessel_fuel_id: nil,
            amount: nil,
            min_amount: nil,
            time_entered: DateTime.utc_now(),
            original_time_entered: DateTime.utc_now(),
            allow_split: true,
            is_traded_bid: false,
            active: true,
            comment: nil,
            # Unused
            credit_terms: nil,
            expiration: nil,
            total_price: nil

  def from_params_to_auction_bid(
        params = %{
          "amount" => amount,
          "comment" => comment,
          "min_amount" => min_amount,
          "vessel_fuel_id" => vessel_fuel_id,
          "supplier_id" => supplier_id,
          "time_entered" => time_entered
        },
        auction = %struct{}
      )
      when is_auction(struct) do
    %__MODULE__{
      id: UUID.uuid4(:hex),
      auction_id: auction.id,
      supplier_id: supplier_id,
      vessel_fuel_id: vessel_fuel_id,
      amount: amount,
      comment: comment,
      min_amount: min_amount,
      time_entered: time_entered,
      original_time_entered: time_entered,
      allow_split: Map.get(params, "allow_split", true),
      is_traded_bid: Map.get(params, "is_traded_bid", false)
    }
  end

  def from_params_to_auction_bid(params, auction),
    do: from_params_to_auction_bid(Map.put(params, "comment", nil), auction)

  # When replaying events, if the Bid struct has changed (particularly when new
  # keys are added), the structs that come out of the events will be invalid.
  # This function ensures that bids from events always have all of the values
  # that the application currently expects from the structs.
  def from_event_bid(bid) do
    %__MODULE__{
      auction_id: nil,
      amount: nil,
      supplier_id: nil,
      vessel_fuel_id: nil
    }
    |> Map.merge(bid)
  end
end
