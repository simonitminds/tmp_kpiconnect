defmodule Oceanconnect.Auctions.AuctionBid do
  @enforce_keys [:auction_id, :amount, :supplier_id, :fuel_id]
  defstruct id: nil,
            auction_id: nil,
            amount: nil,
            credit_terms: nil,
            fuel_id: nil,
            expiration: nil,
            is_traded_bid: false,
            min_amount: nil,
            supplier_id: nil,
            total_price: nil,
            time_entered: DateTime.utc_now(),
            comment: nil,
            active: true

  def from_params_to_auction_bid(
        params = %{
          "amount" => amount,
          "min_amount" => min_amount,
          "fuel_id" => fuel_id,
          "supplier_id" => supplier_id,
          "time_entered" => time_entered
        },
        auction = %Oceanconnect.Auctions.Auction{}
      ) do
    %__MODULE__{
      id: UUID.uuid4(:hex),
      auction_id: auction.id,
      amount: amount,
      is_traded_bid: Map.get(params, "is_traded_bid", false),
      fuel_id: fuel_id,
      min_amount: min_amount,
      supplier_id: supplier_id,
      time_entered: time_entered
    }
  end
end
