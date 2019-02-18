defmodule Oceanconnect.Auctions.Payloads.SolutionsPayload do
  import Oceanconnect.Auctions.Guards

  alias Oceanconnect.Auctions.{Auction, TermAuction, AuctionBid, AuctionSuppliers, Solution}

  defstruct lowest_bids: [],
            bid_history: [],
            is_leading: false,
            lead_is_tied: false

  def get_solutions_payload!(
        _state = %state_struct{solutions: solutions, winning_solution: winning_solution},
        auction: auction = %struct{buyer_id: buyer_id},
        buyer: buyer_id
      ) when is_auction_state(state_struct) and is_auction(struct) do
    other_solutions = list_other_solutions(solutions, winning_solution)

    %{
      best_single_supplier: scrub_solution_for_buyer(solutions.best_single_supplier, auction),
      best_overall: scrub_solution_for_buyer(solutions.best_overall, auction),
      best_by_supplier:
        Enum.reduce(solutions.best_by_supplier, %{}, fn {supplier_id, solution}, acc ->
          scrubbed_solution = scrub_solution_for_buyer(solution, auction)
          supplier_alias = AuctionSuppliers.get_name_or_alias(supplier_id, auction)
          Map.put(acc, supplier_alias, scrubbed_solution)
        end),
      winning_solution: scrub_solution_for_buyer(winning_solution, auction),
      other_solutions: scrub_solutions_for_buyer(other_solutions, auction)
    }
  end

  def get_solutions_payload!(
        _state = %state_struct{solutions: solutions, winning_solution: winning_solution},
        auction: auction = %struct{},
        supplier: supplier_id
      ) when is_auction_state(state_struct) and is_auction(struct) do
    suppliers_best_solution = Map.get(solutions.best_by_supplier, supplier_id)
    next_best_solution =
      list_other_solutions(solutions, suppliers_best_solution)
      |> Enum.at(0)

    %{
      best_single_supplier:
        scrub_solution_for_supplier(solutions.best_single_supplier, supplier_id, auction),
      best_overall: scrub_solution_for_supplier(solutions.best_overall, supplier_id, auction),
      suppliers_best_solution: scrub_solution_for_supplier(suppliers_best_solution, supplier_id, auction),
      winning_solution: scrub_solution_for_supplier(winning_solution, supplier_id, auction),
      next_best_solution: scrub_solution_for_supplier(next_best_solution, supplier_id, auction)
    }
  end

  defp list_other_solutions(
         _solutions = %{
           best_overall: _best_overall,
           best_by_supplier: best_by_supplier,
           best_single_supplier: best_single_supplier
         },
         nil
       ) do
    supplier_id = supplier_for_solution(best_single_supplier)

    best_by_supplier
    |> Map.delete(supplier_id)
    |> Map.values()
    |> Enum.sort_by(&Solution.sort_tuple/1)
  end

  defp list_other_solutions(
         _solutions = %{
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
    |> Enum.sort_by(&Solution.sort_tuple/1)
  end

  defp scrub_solution_for_supplier(nil, _supplier_id, _auction), do: nil
  defp scrub_solution_for_supplier(%Solution{bids: []}, _supplier_id, _auction), do: nil
  defp scrub_solution_for_supplier(solution = %Solution{bids: bids}, supplier_id, auction) do
    %Solution{
      solution
      | bids: Enum.map(bids, fn bid -> scrub_bid_for_supplier(bid, supplier_id, auction) end)
    }
  end

  defp scrub_solution_for_buyer(nil, _auction), do: nil
  defp scrub_solution_for_buyer(%Solution{bids: []}, _auction), do: nil
  defp scrub_solution_for_buyer(solution = %Solution{bids: bids}, auction) do
    %Solution{solution | bids: Enum.map(bids, fn bid -> scrub_bid_for_buyer(bid, auction) end)}
  end

  defp scrub_solutions_for_buyer(solutions, auction) when is_list(solutions) do
    Enum.map(solutions, fn solution -> scrub_solution_for_buyer(solution, auction) end)
    |> Enum.filter(& &1)
  end

  # TODO: dedupe this across payloads
  defp scrub_bid_for_supplier(nil, _supplier_id, _auction), do: nil

  defp scrub_bid_for_supplier(
         bid = %AuctionBid{supplier_id: supplier_id},
         supplier_id,
         auction = %struct{}
       ) when is_auction(struct) do
    %{bid | min_amount: bid.min_amount, comment: bid.comment }
    |> Map.put(:product, product_for_bid(bid, auction))
    |> Map.from_struct()
  end

  defp scrub_bid_for_supplier(bid = %AuctionBid{}, _supplier_id, auction = %struct{}) when is_auction(struct) do
    %{bid | min_amount: nil, comment: nil, is_traded_bid: false}
    |> Map.from_struct()
    |> Map.put(:product, product_for_bid(bid, auction))
    |> Map.delete(:supplier_id)
  end

  defp scrub_bid_for_buyer(nil, _auction), do: nil

  defp scrub_bid_for_buyer(bid = %AuctionBid{}, auction = %struct{}) when is_auction(struct) do
    supplier = AuctionSuppliers.get_name_or_alias(bid.supplier_id, auction)

    %{bid | supplier_id: nil, min_amount: nil}
    |> Map.from_struct()
    |> Map.put(:product, product_for_bid(bid, auction))
    |> Map.put(:supplier, supplier)
  end

  defp product_for_bid(bid, %Auction{auction_vessel_fuels: vessel_fuels}) do
    vf = Enum.find(vessel_fuels, &("#{&1.id}" == bid.vessel_fuel_id))
    vessel = vf.vessel.name
    fuel = vf.fuel.name
    "#{fuel} for #{vessel}"
  end

  defp product_for_bid(_bid, %TermAuction{fuel: fuel}) do
    "#{fuel.name}"
  end

  defp supplier_for_solution(nil), do: nil

  defp supplier_for_solution(%Solution{bids: bids}) when is_list(bids) do
    case bids do
      [] -> nil
      [bid | _] -> bid.supplier_id
    end
  end
end
