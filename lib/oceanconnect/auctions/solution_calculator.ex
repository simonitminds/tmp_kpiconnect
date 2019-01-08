defmodule Oceanconnect.Auctions.SolutionCalculator do
  alias Oceanconnect.Auctions.{Auction, Solution}
  alias Oceanconnect.Auctions.AuctionStore.{AuctionState}

  defstruct best_single_supplier: %Solution{},
            best_overall: %Solution{},
            best_by_supplier: %{}

  defmodule BidGroup do
    defstruct bids: [],
              products: [],
              total_price: 0,
              latest_original_time_entered: nil,
              auction_id: nil

    def create(bids, _auction = %Auction{id: auction_id, auction_vessel_fuels: vessel_fuels}) do
      total_price =
        Enum.reduce(bids, 0, fn(bid, acc) ->
          vf = Enum.find(vessel_fuels, &("#{&1.id}" == bid.vessel_fuel_id))
          case vf do
            nil -> 0
            _ -> acc + bid.amount * vf.quantity
          end
        end)

      bid_products =
        bids
        |> Enum.map(&(&1.vessel_fuel_id))
        |> Enum.sort()

      %__MODULE__{
        bids: bids,
        products: bid_products,
        total_price: total_price,
        latest_original_time_entered: latest_original_time_entered(bids),
        auction_id: auction_id
      }
    end

    defp latest_original_time_entered(bids) do
      bids
      |> Enum.map(& &1.original_time_entered)
      |> Enum.sort(&(DateTime.compare(&1, &2) == :gt))
      |> hd()
    end

    def sort_tuple(group) do
      latest_original_time_entered =
        if group.latest_original_time_entered do
          DateTime.to_unix(group.latest_original_time_entered, :microsecond)
        else
          DateTime.utc_now()
        end

      {group.total_price, latest_original_time_entered}
    end
  end


  def process(current_state = %AuctionState{product_bids: product_bids, solutions: existing_solutions}, auction = %Auction{}) do
    best_by_supplier = best_solutions_by_supplier(product_bids, auction)
    best_single_supplier = calculate_best_single_supplier(product_bids, auction, supplier_solutions: best_by_supplier)
    best_overall = calculate_best_overall(product_bids, auction, best_single_supplier: best_single_supplier)

    solution_state = %__MODULE__{
      best_by_supplier: best_by_supplier,
      best_single_supplier: best_single_supplier,
      best_overall: best_overall
    }

    Map.put(current_state, :solutions, solution_state)
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


  # Best single supplier solution is the combination of bids from a given
  # supplier that has the lowest average price:
  #   ∑ (unit_price * fuel_quantity) / total_quantity.
  defp calculate_best_single_supplier(_product_bids, _auction, supplier_solutions: supplier_solutions) do
    supplier_solutions
    |> Map.values()
    |> Enum.filter(& &1.valid)
    |> Enum.sort_by(&Solution.sort_tuple/1)
    # list may be empty, so avoid `hd` and return a blank solution instead.
    |> Enum.at(0, %Solution{valid: false})
  end


  # Best overall solution is the combination of the lowest bids for each fuel,
  # respecting supplier's allow_split requests.
  defp calculate_best_overall(product_bids, auction, best_single_supplier: best_single_supplier) do
    products = Map.keys(product_bids)
    product_count = Enum.count(products)

    groups =
      create_bid_groups(product_bids)
      |> Enum.map(&(BidGroup.create(&1, auction)))
      |> Enum.sort_by(&BidGroup.sort_tuple/1)
      |> Enum.uniq_by(&(&1.products))

    possible_solutions =
      combinations(groups)
      |> Enum.filter(fn(groups) ->
        groups
        |> Enum.flat_map(&(&1.products))
        |> Enum.sort()
        |> Kernel.==(products)
      end)
      |> Enum.map(fn(groups) ->
        groups
        |> Enum.flat_map(&(&1.bids))
        |> Solution.from_bids(product_bids, auction)
      end)

    possible_solutions ++ [best_single_supplier]
    |> Enum.min_by(&Solution.sort_tuple/1)
  end

  defp create_bid_groups(product_bids) do
    bids_by_suppliers =
      Enum.reduce(product_bids, %{}, fn({_vfid, bid_state}, acc) ->
        Enum.reduce(bid_state.lowest_bids, acc, fn(bid, acc) ->
          bid_list = Map.get(acc, bid.supplier_id, [])
          Map.put(acc, bid.supplier_id, [bid | bid_list])
        end)
      end)

    Enum.flat_map(bids_by_suppliers, fn({_supplier, bids}) -> groups_from_bidlist(bids) end)
  end

  defp groups_from_bidlist(bids) do
    # Every splittable bid gets its own group, since they can be selected
    # individually.
    splittable_groups =
      bids
      |> Enum.filter(&(&1.allow_split))
      |> Enum.map(&([&1]))

    # If any bids are unsplittable, make a group containing all bids in the list.
    # This represents the option of selecting the unsplittable bid and having to
    # bring along all the other bids with it.
    unsplittable_groups = if Enum.any?(bids, &(!&1.allow_split)), do: [bids], else: []

    splittable_groups ++ unsplittable_groups
  end

  # Taken from:
  # https://github.com/tallakt/comb/blob/e6660924891d88d798494ab0c5adeefb29fae8b8/lib/comb/naive.ex
  defp combinations(_, 0), do: [[]]
  defp combinations([], _), do: []
  defp combinations([h|t], k) do
    ((for l <- combinations(t, k - 1), do: [h|l]) ++ combinations(t, k))
    |> Enum.uniq
  end
  defp combinations(enum, k), do: combinations(Enum.to_list(enum), k)
  def combinations(enum) do
    n = Enum.count(enum)
    1..n
    |> Enum.flat_map(&(do_subsets_for_n(enum, &1)))
  end
  defp do_subsets_for_n(enum, n) do
    enum
    |> combinations(n)
  end
end
