defmodule Oceanconnect.Auctions.TermAuctionState do
  alias __MODULE__
  alias Oceanconnect.Auctions.{TermAuction, SolutionCalculator, ProductBidState}

  defstruct auction_id: nil,
            status: :pending,
            solutions: %SolutionCalculator{},
            submitted_barges: [],
            product_bids: %{},
            winning_solution: nil

  def from_auction(%TermAuction{id: auction_id, scheduled_start: nil}) do
    %TermAuctionState{
      auction_id: auction_id,
      status: :draft
    }
  end

  def from_auction(%TermAuction{id: auction_id, fuel: fuel}) do
    %TermAuctionState{
      auction_id: auction_id,
      product_bids: %{"#{fuel.id}" => ProductBidState.for_product(fuel.id, auction_id)}
    }
  end

  def update_product_bids(state, product_key, new_product_state) do
    %TermAuctionState{
      state
      | product_bids: Map.put(state.product_bids, "#{product_key}", new_product_state)
    }
  end

  def get_state_for_product(state, product_key) do
    Map.get(state.product_bids, "#{product_key}")
  end
end
