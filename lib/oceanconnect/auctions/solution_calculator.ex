defmodule Oceanconnect.Auctions.SolutionCalculator do
  alias Oceanconnect.Auctions.{Auction, Solution}
  alias Oceanconnect.Auctions.AuctionStore.{AuctionState}

  defstruct best_single_supplier: %Solution{},
    best_overall: %Solution{},
    best_by_supplier: %{}


  def process(current_state = %AuctionState{product_bids: product_bids}, auction = %Auction{}) do
    best_by_supplier = best_solutions_by_supplier(product_bids, auction)

    solution_state = %__MODULE__{
      best_overall: calculate_solution(product_bids, auction, :best_overall),
      best_by_supplier: best_by_supplier,
      best_single_supplier: calculate_solution(product_bids, auction, :best_single_supplier, supplier_solutions: best_by_supplier)
    }

    Map.put(current_state, :solutions, solution_state)
  end

  # Best single supplier solution is the combination of bids from a given
  # supplier that has the lowest average price:
  #   ∑ (unit_price * fuel_quantity) / total_quantity.
  defp calculate_solution(product_bids, _auction, :best_single_supplier, supplier_solutions: supplier_solutions) do
    supplier_solutions
    |> Map.values()
    |> Enum.filter(&(&1.valid))
    |> Enum.sort(&Solution.less_equal/2)
    |> Enum.at(0, %Solution{valid: false}) # list may be empty, so avoid `hd` and return `nil` instead.
  end

  # Best overall solution is the combination of the lowest bids for each fuel.
  defp calculate_solution(product_bids, auction, :best_overall) do
    solution_bids = product_bids
    |> Enum.map(fn({_product_id, bid_state}) ->
      Enum.at(bid_state.lowest_bids, 0)
    end)
    |> Enum.filter(&(&1))

    Solution.from_bids(solution_bids, product_bids, auction)
  end

  # Returns a map of single supplier solutions keyed by the supplier's id.
  # Expects `lowest_bids` to only ever have one bid from a supplier (should be
  # guaranteed by AuctionBidCalculator).
  defp best_solutions_by_supplier(product_bids, auction) do
    lowest_bids_by_supplier = product_bids
    |> Enum.flat_map(fn({_product, bid_state}) -> bid_state.lowest_bids end)
    |> Enum.reduce(%{}, fn(bid, acc) ->
      if Map.has_key?(acc, bid.supplier_id) do
        Map.put(acc, bid.supplier_id, [bid | acc[bid.supplier_id]])
      else
        Map.put(acc, bid.supplier_id, [bid])
      end
    end)

    Enum.reduce(lowest_bids_by_supplier, %{}, fn({supplier_id, bids}, acc) ->
      Map.put(acc, supplier_id, Solution.from_bids(bids, product_bids, auction))
    end)
  end
end
