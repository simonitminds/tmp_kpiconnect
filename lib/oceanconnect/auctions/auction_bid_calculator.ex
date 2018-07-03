defmodule Oceanconnect.Auctions.AuctionBidCalculator do
  alias Oceanconnect.Auctions.{AuctionBidList.AuctionBid}
  alias Oceanconnect.Auctions.AuctionStore.AuctionState


  def process(current_state = %AuctionState{status: :pending}) do
    current_state
  end

  def process(
        current_state = %AuctionState{
          auction_id: _auction_id,
          status: :open,
          minimum_bids: [],
          bids: [],
          lowest_bids: [],
          active_bids: [],
          inactive_bids: []
        }
      ) do
    current_state
  end

  def process(
        current_state = %AuctionState{
          auction_id: _auction_id,
          status: :open,
          minimum_bids: _min_bids,
          bids: [],
          lowest_bids: [],
          active_bids: [],
          inactive_bids: []
        }
      ) do
    current_state
    |> enter_opening_bids
    |> decrement_auto_bids
  end
  def process(
        current_state = %AuctionState{
          auction_id: _auction_id,
          status: :open,
          minimum_bids: _min_bids,
          bids: _bids,
          lowest_bids: _lowest_bids,
          active_bids: _active_bids,
          inactive_bids: _inactive_bids
        }
      ) do

    current_state
    |> sort_lowest_bids
    |> decrement_auto_bids
  end

  defp enter_opening_bids(state = %AuctionState{minimum_bids: min_bids}) do
    enter_auto_bids(state, min_bids)
  end

  def enter_auto_bid(
        current_state = %AuctionState{
          bids: bids,
          minimum_bids: min_bids,
          active_bids: active_bids
        },
        bid = %AuctionBid{min_amount: min_amount}
      )
      when is_float(min_amount) do
    %AuctionState{
      current_state
      | bids: [bid | bids],
        minimum_bids: [bid | min_bids],
        active_bids: [bid | active_bids]
    }
    |> process
  end

  defp enter_auto_bids(state = %AuctionState{bids: bids}, []) do
    # TODO I'm not super sure why I need to do this instead of just returning state
    inactive_bids = Enum.filter(bids, fn bid -> bid.active == false end)
    %AuctionState{state | inactive_bids: inactive_bids}
  end

  defp enter_auto_bids(state = %AuctionState{}, remaining_min_bids) do
    Enum.reduce(remaining_min_bids, state, fn bid, acc ->
      updated_bid = %AuctionBid{bid | id: UUID.uuid4(:hex), time_entered: DateTime.utc_now()}

      acc
      |> invalidate_previous_auto_bids(updated_bid)
      |> invalidate_previous_bids(updated_bid)
      |> enter_bid(updated_bid)
      |> add_auto_bid(updated_bid)
    end)
  end

  defp decrement_auto_bids(state = %AuctionState{minimum_bids: min_bids}) do
    decremented_auto_bids = decrement_auto_bids_that_can_be_decremented(state, min_bids)

    if length(decremented_auto_bids) > 0 do
      enter_auto_bids(state, decremented_auto_bids)
      |> decrement_auto_bids
    else
      state
    end
  end

  defp decrement_auto_bids_that_can_be_decremented(
         %AuctionState{lowest_bids: lowest_bids},
         min_bids
       ) do
    lowest_bid = hd(lowest_bids)
    lowest_amount = lowest_bid.amount

    min_bids
    |> Enum.filter(fn bid = %AuctionBid{amount: amount, min_amount: min_amount} ->
      amount >= lowest_amount && min_amount <= lowest_amount &&
        lowest_bid.supplier_id != bid.supplier_id
    end)
    |> Enum.map(fn bid ->
      cond do
        bid.amount - 0.25 >= bid.min_amount -> %AuctionBid{bid | amount: bid.amount - 0.25}
        bid.amount - 0.25 < bid.min_amount -> %AuctionBid{bid | amount: bid.min_amount}
      end
    end)
  end

  def enter_bid(
        current_state = %AuctionState{
          auction_id: auction_id,
          status: :open,
          lowest_bids: [],
          minimum_bids: [],
          bids: []
        },
        bid = %AuctionBid{auction_id: auction_id}
      ) do
    %AuctionState{current_state | bids: [bid], active_bids: [bid], lowest_bids: [bid]}
  end

  def enter_bid(
        current_state = %AuctionState{
          auction_id: auction_id,
          status: :pending,
          minimum_bids: _min_bids,
          bids: _bids,
          lowest_bids: _lowest_bids,
          inactive_bids: _inactive_bids
        },
        bid = %AuctionBid{
          auction_id: auction_id,
          amount: _amount,
          min_amount: min_amount,
          supplier_id: _supplier_id
        }
      )
      when is_float(min_amount) do
    current_state
    |> invalidate_previous_bids(bid)
    |> sort_lowest_bids
    |> add_auto_bid(bid)
  end

  def enter_bid(
        current_state = %AuctionState{
          auction_id: auction_id,
          status: :open,
          bids: _bids,
          lowest_bids: _lowest_bids,
          inactive_bids: _inactive_bids
        },
        bid = %AuctionBid{
          auction_id: auction_id,
          amount: _amount,
          supplier_id: _supplier_id
        }
      ) do
    current_state
    |> invalidate_previous_bids(bid)
    |> add_bid(bid)
    |> sort_lowest_bids
  end

  defp add_bid(state = %AuctionState{bids: bids, active_bids: active_bids}, bid = %AuctionBid{}) do
    %AuctionState{state | bids: [bid | bids], active_bids: [bid | active_bids]}
  end

  defp add_auto_bid(
         state = %AuctionState{status: :pending, bids: _bids, minimum_bids: min_bids},
         bid = %AuctionBid{}
       ) do
    %AuctionState{state | minimum_bids: [bid | min_bids]}
  end

  defp add_auto_bid(
         state = %AuctionState{status: :open, bids: _bids, minimum_bids: min_bids},
         bid = %AuctionBid{}
       ) do
    %AuctionState{state | minimum_bids: [bid | min_bids]}
  end

  defp sort_lowest_bids(state = %AuctionState{active_bids: active_bids}) do
    lowest_bids =
      active_bids
      |> Enum.sort_by(&{&1.amount, &1.time_entered})

    %AuctionState{state | lowest_bids: lowest_bids}
  end

  defp invalidate_previous_bids(
         state = %AuctionState{
           bids: bids,
           lowest_bids: _lowest_bids,
           active_bids: active_bids,
           inactive_bids: _inactive_bids
         },
         _new_bid = %AuctionBid{supplier_id: supplier_id}
       ) do
    {suppliers_old_bids, others_bids} =
      Enum.split_with(active_bids, fn bid -> bid.supplier_id == supplier_id end)

    updated_bids =
      bids
      |> Enum.map(fn bid ->
        case bid in suppliers_old_bids do
          true -> %AuctionBid{bid | active: false}
          false -> bid
        end
      end)

    inactive_bids = Enum.filter(updated_bids, &(&1.active == false))
    %AuctionState{
      state
      | inactive_bids: inactive_bids,
        active_bids: others_bids,
        bids: updated_bids
    }
  end

  defp invalidate_previous_auto_bids(
         state = %AuctionState{bids: bids, minimum_bids: min_bids},
         new_bid = %AuctionBid{amount: _amount, min_amount: _min_amound}
       ) do
    {suppliers_old_bids, others_bids} =
      Enum.split_with(min_bids, fn bid -> bid.supplier_id == new_bid.supplier_id end)

    updated_bids =
      bids
      |> Enum.map(fn bid ->
        case bid in suppliers_old_bids do
          true -> %AuctionBid{bid | active: false}
          false -> bid
        end
      end)

    inactive_bids = Enum.filter(updated_bids, &(&1.active == false))
    %AuctionState{
      state
      | inactive_bids: inactive_bids,
        bids: updated_bids,
        minimum_bids: others_bids
    }
  end
end
