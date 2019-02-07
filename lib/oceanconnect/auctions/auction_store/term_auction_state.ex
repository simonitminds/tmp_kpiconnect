defmodule Oceanconnect.Auctions.AuctionStore.TermAuctionState do
  alias Oceanconnect.Auctions.{TermAuction, SolutionCalculator, AuctionStore.ProductBidState}

  defstruct auction_id: nil,
            status: :pending,
            solutions: %SolutionCalculator{},
            submitted_barges: [],
            product_bids: %{},
            winning_solution: nil

  def from_auction(%TermAuction{id: auction_id, scheduled_start: nil}) do
    %__MODULE__{
      auction_id: auction_id,
      status: :draft
    }
  end

  def from_auction(%TermAuction{id: auction_id, fuel: fuel}) do
    %__MODULE__{
      auction_id: auction_id,
      product_bids: %{"#{fuel.id}" => ProductBidState.for_product(fuel.id, auction_id)}
    }
  end

  def update_product_bids(state = %__MODULE__{}, product_key, new_product_state) do
    %__MODULE__{
      state
      | product_bids: Map.put(state.product_bids, "#{product_key}", new_product_state)
    }
  end

  def get_state_for_product(state = %__MODULE__{}, product_key) do
    Map.get(state.product_bids, "#{product_key}")
  end
end
