defmodule Oceanconnect.Auctions.AuctionStore.ProductBidState do
  defstruct auction_id: nil,
            vessel_fuel_id: nil,
            lowest_bids: [],
            minimum_bids: [],
            bids: [],
            active_bids: [],
            inactive_bids: []

  def for_product(vessel_fuel_id, auction_id) do
    %__MODULE__{
      auction_id: auction_id,
      vessel_fuel_id: vessel_fuel_id
    }
  end
end
