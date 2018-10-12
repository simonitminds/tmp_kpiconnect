defmodule Oceanconnect.Auctions.Payloads.SolutionsPayload do
  alias Oceanconnect.Auctions.{Auction, AuctionBid}
  alias Oceanconnect.Auctions.AuctionStore.{AuctionState}
  alias Oceanconnect.Auctions.Solution

  defstruct lowest_bids: [],
            bid_history: [],
            is_leading: false,
            lead_is_tied: false

  def get_solutions_payload!(
        _state = %AuctionState{solutions: solutions, winning_solution: winning_solution},
        [auction: auction = %Auction{buyer_id: buyer_id},
        buyer: buyer_id]
      ) do
    other_solutions = list_other_solutions(solutions, winning_solution)

    %{
      best_single_supplier: scrub_solution_for_buyer(solutions.best_single_supplier, auction),
      best_overall: scrub_solution_for_buyer(solutions.best_overall, auction),
      best_by_supplier:
        Enum.reduce(solutions.best_by_supplier, %{}, fn {supplier_id, solution}, acc ->
          scrubbed_solution = scrub_solution_for_buyer(solution, auction)
          supplier_alias = get_name_or_alias(supplier_id, auction)
          Map.put(acc, supplier_alias, scrubbed_solution)
        end),
      winning_solution: scrub_solution_for_buyer(winning_solution, auction),
      other_solutions: scrub_solutions_for_buyer(other_solutions, auction)
    }
  end

  def get_solutions_payload!(
        _state = %AuctionState{solutions: solutions, winning_solution: winning_solution},
        auction: _auction,
        supplier: supplier_id
      ) do
    %{
      best_single_supplier:
        scrub_solution_for_supplier(solutions.best_single_supplier, supplier_id),
      best_overall: scrub_solution_for_supplier(solutions.best_overall, supplier_id),
      winning_solution: scrub_solution_for_supplier(winning_solution, supplier_id)
    }
  end

  defp list_other_solutions(
         solutions = %{
           best_overall: best_overall,
           best_by_supplier: best_by_supplier,
           best_single_supplier: best_single_supplier
         },
         nil
       ) do
    supplier_id = supplier_for_solution(best_single_supplier)

    best_by_supplier
    |> Map.delete(supplier_id)
    |> Map.values()
    |> Enum.sort_by(fn solution -> solution.normalized_price end)
  end

  defp list_other_solutions(
         solutions = %{
           best_overall: best_overall,
           best_by_supplier: best_by_supplier,
           best_single_supplier: best_single_supplier
         },
         %Solution{bids: winning_bids}
       ) do
    supplier_solutions = Map.values(best_by_supplier)

    [best_overall, best_single_supplier | supplier_solutions]
    |> Enum.reject(fn solution -> solution == nil end)
    |> Enum.reject(fn %{bids: bids} -> bids == winning_bids end)
    |> Enum.uniq()
    |> Enum.sort_by(fn solution -> solution.normalized_price end)
  end

  defp scrub_solution_for_supplier(nil, _supplier_id), do: nil

  defp scrub_solution_for_supplier(solution = %Solution{bids: bids}, supplier_id) do
    %Solution{
      solution
      | bids: Enum.map(bids, fn bid -> scrub_bid_for_supplier(bid, supplier_id) end)
    }
  end

  defp scrub_solutions_for_supplier(solutions, supplier_id) when is_list(solutions) do
    Enum.map(solutions, fn solution -> scrub_solution_for_supplier(solution, auction) end)
  end

  defp scrub_solution_for_buyer(nil, _auction), do: nil

  defp scrub_solution_for_buyer(solution = %Solution{bids: bids}, auction) do
    %Solution{solution | bids: Enum.map(bids, fn bid -> scrub_bid_for_buyer(bid, auction) end)}
  end

  defp scrub_solutions_for_buyer(solutions, auction) when is_list(solutions) do
    Enum.map(solutions, fn solution -> scrub_solution_for_buyer(solution, auction) end)
  end

  # TODO: dedupe this across payloads
  defp scrub_bid_for_supplier(nil, _supplier_id), do: nil

  defp scrub_bid_for_supplier(bid = %AuctionBid{supplier_id: supplier_id}, supplier_id) do
    %{bid | min_amount: bid.min_amount, comment: bid.comment}
    |> Map.from_struct()
  end

  defp scrub_bid_for_supplier(bid = %AuctionBid{}, _supplier_id) do
    %{bid | min_amount: nil, comment: nil, is_traded_bid: nil}
    |> Map.from_struct()
    |> Map.delete(:supplier_id)
  end

  defp scrub_bid_for_buyer(nil, _auction), do: nil

  defp scrub_bid_for_buyer(bid = %AuctionBid{}, auction = %Auction{}) do
    supplier = get_name_or_alias(bid.supplier_id, auction)

    %{bid | supplier_id: nil, min_amount: nil}
    |> Map.from_struct()
    |> Map.put(:supplier, supplier)
  end

  defp get_name_or_alias(supplier_id, %Auction{anonymous_bidding: true, suppliers: suppliers}) do
    hd(Enum.filter(suppliers, &(&1.id == supplier_id))).alias_name
  end

  defp get_name_or_alias(supplier_id, %Auction{suppliers: suppliers}) do
    hd(Enum.filter(suppliers, &(&1.id == supplier_id))).name
  end

  defp supplier_for_solution(nil), do: nil

  defp supplier_for_solution(solution = %Solution{bids: bids}) when is_list(bids) do
    case bids do
      [] -> nil
      [bid | _] -> bid.supplier_id
    end
  end
end
