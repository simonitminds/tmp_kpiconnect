defmodule Oceanconnect.Auctions.SpotAuctionState do
  alias __MODULE__
  alias Oceanconnect.Auctions.{Auction, SolutionCalculator, ProductBidState}

  defstruct auction_id: nil,
            status: :pending,
            solutions: %SolutionCalculator{},
            submitted_barges: [],
            product_bids: %{},
            winning_solution: nil

  def from_auction(%Auction{id: auction_id, scheduled_start: nil}) do
    %SpotAuctionState{
      auction_id: auction_id,
      status: :draft
    }
  end

  def from_auction(%Auction{id: auction_id, auction_vessel_fuels: vessel_fuels}) do
    product_bids =
      Enum.reduce(vessel_fuels, %{}, fn %{id: vf_id}, acc ->
        Map.put(acc, "#{vf_id}", ProductBidState.for_product(vf_id, auction_id))
      end)

    %SpotAuctionState{
      auction_id: auction_id,
      product_bids: product_bids
    }
  end

  def update_product_bids(state, product_key, new_product_state) do
    %SpotAuctionState{
      state
      | product_bids: Map.put(state.product_bids, "#{product_key}", new_product_state)
    }
  end

  def get_state_for_product(state, product_key) do
    Map.get(state.product_bids, "#{product_key}")
  end
end
