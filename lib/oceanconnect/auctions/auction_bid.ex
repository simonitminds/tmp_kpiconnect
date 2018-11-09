defmodule Oceanconnect.Auctions.AuctionBid do
  @enforce_keys [:auction_id, :amount, :supplier_id, :fuel_id]
  defstruct id: nil,
            auction_id: nil,
            supplier_id: nil,
            fuel_id: nil,
            active: true,
            comment: nil,
            amount: nil,
            min_amount: nil,
            allow_split: true,
            is_traded_bid: false,
            time_entered: DateTime.utc_now(),
            original_time_entered: DateTime.utc_now(),
            credit_terms: nil,
            expiration: nil,
            total_price: nil

  def from_params_to_auction_bid(
        params = %{
          "amount" => amount,
          "min_amount" => min_amount,
          "fuel_id" => fuel_id,
          "supplier_id" => supplier_id,
          "time_entered" => time_entered,
        },
        auction = %Oceanconnect.Auctions.Auction{}
      ) do
    %__MODULE__{
      id: UUID.uuid4(:hex),
      auction_id: auction.id,
      amount: amount,
      is_traded_bid: Map.get(params, "is_traded_bid", false),
      allow_split: Map.get(params, "allow_split", true),
      fuel_id: fuel_id,
      min_amount: min_amount,
      supplier_id: supplier_id,
      time_entered: time_entered,
      original_time_entered: time_entered
    }
  end


  # When replaying events, if the Bid struct has changed (particularly when new
  # keys are added), the structs that come out of the events will be invalid.
  # This function ensures that bids from events always have all of the values
  # that the application currently expects from the structs.
  def from_event_bid(bid) do
    %__MODULE__{
      auction_id: nil,
      amount: nil,
      supplier_id: nil,
      fuel_id: nil
    }
    |> Map.merge(bid)
  end
end
