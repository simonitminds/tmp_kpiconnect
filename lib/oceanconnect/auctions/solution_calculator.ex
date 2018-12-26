defmodule Oceanconnect.Auctions.SolutionCalculator do
  alias Oceanconnect.Auctions.{Auction, Solution}
  alias Oceanconnect.Auctions.AuctionStore.{AuctionState}

  defstruct best_single_supplier: %Solution{},
            best_overall: %Solution{},
            best_by_supplier: %{}

  def process(current_state = %AuctionState{product_bids: product_bids}, auction = %Auction{}) do
    best_by_supplier = best_solutions_by_supplier(product_bids, auction)
    best_single_supplier = calculate_solution(product_bids, auction, :best_single_supplier, supplier_solutions: best_by_supplier)
    best_overall = calculate_solution(product_bids, auction, :best_overall, best_single_supplier: best_single_supplier)

    solution_state = %__MODULE__{
      best_by_supplier: best_by_supplier,
      best_single_supplier: best_single_supplier,
      best_overall: best_overall
    }

    Map.put(current_state, :solutions, solution_state)
  end

  # Best single supplier solution is the combination of bids from a given
  # supplier that has the lowest average price:
  #   ∑ (unit_price * fuel_quantity) / total_quantity.
  defp calculate_solution(_product_bids, _auction, :best_single_supplier,
         supplier_solutions: supplier_solutions
       ) do
    supplier_solutions
    |> Map.values()
    |> Enum.filter(& &1.valid)
    |> Enum.sort_by(&Solution.sort_tuple/1)
    # list may be empty, so avoid `hd` and return a blank solution instead.
    |> Enum.at(0, %Solution{valid: false})
  end

  # Best overall solution is the combination of the lowest bids for each fuel,
  # respecting supplier's allow_split requests.
  defp calculate_solution(product_bids, auction, :best_overall,
         best_single_supplier: best_single_supplier
       ) do
    solution_bids =
      product_bids
      |> Enum.map(fn {_product_id, bid_state} ->
        bid_state.lowest_bids
        |> Enum.filter(& &1.allow_split)
        |> Enum.at(0)
      end)
      |> Enum.filter(& &1)

    best_split =
      case solution_bids do
        [] -> %Solution{valid: false}
        bids -> Solution.from_bids(bids, product_bids, auction)
      end

    [best_split, best_single_supplier]
    |> Enum.min_by(&Solution.sort_tuple/1)
  end

  # Returns a map of single supplier solutions keyed by the supplier's id.
  # Expects `lowest_bids` to only ever have one bid from a supplier (should be
  # guaranteed by AuctionBidCalculator).
  defp best_solutions_by_supplier(product_bids, auction) do
    lowest_bids_by_supplier =
      product_bids
      |> Enum.flat_map(fn {_product, bid_state} -> bid_state.lowest_bids end)
      |> Enum.reduce(%{}, fn bid, acc ->
        if Map.has_key?(acc, bid.supplier_id) do
          Map.put(acc, bid.supplier_id, [bid | acc[bid.supplier_id]])
        else
          Map.put(acc, bid.supplier_id, [bid])
        end
      end)

    Enum.reduce(lowest_bids_by_supplier, %{}, fn {supplier_id, bids}, acc ->
      Map.put(acc, supplier_id, Solution.from_bids(bids, product_bids, auction))
    end)
  end
end
