defmodule Oceanconnect.Auctions.AuctionBidCalculator do
  alias Oceanconnect.Auctions.{AuctionBid, AuctionEvent}
  alias Oceanconnect.Auctions.AuctionStore.AuctionState

  def process(current_state = %AuctionState{}, bid = %AuctionBid{min_amount: min_amount})
      when is_float(min_amount) do
    enter_auto_bid(current_state, bid)
    |> process
  end

  def process(current_state = %AuctionState{}, bid = %AuctionBid{}) do
    enter_bid(current_state, bid)
    |> process
  end

  def process(current_state = %AuctionState{status: :pending}) do
    {current_state, []}
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
    {current_state, []}
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
    {state, events} =
      current_state
      |> enter_opening_bids
      |> decrement_auto_bids

    next_state =
      state
      |> sort_lowest_bids

    {next_state, events}
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
    {state, events} =
      current_state
      |> sort_lowest_bids
      |> decrement_auto_bids

    next_state =
      state
      |> sort_lowest_bids

    {next_state, events}
  end

  defp enter_opening_bids(state = %AuctionState{minimum_bids: min_bids}) do
    enter_auto_bids(state, min_bids)
  end

  defp enter_auto_bid(
         current_state = %AuctionState{lowest_bids: lowest_bids},
         bid = %AuctionBid{min_amount: min_amount}
       )
       when is_float(min_amount) do
    existing_min_amount =
      case lowest_bids do
        [] -> min_amount
        [head | _] -> head.amount
      end

    matching_lowest_amount = Enum.max([existing_min_amount, min_amount])
    bid = %AuctionBid{bid | amount: bid.amount || matching_lowest_amount}

    current_state
    |> invalidate_previous_auto_bids(bid)
    |> add_auto_bid(bid)
  end

  defp enter_auto_bids(state = %AuctionState{bids: bids}, []) do
    # TODO I'm not super sure why I need to do this instead of just returning state

    inactive_bids = Enum.filter(bids, fn bid -> bid.active == false end)
    %AuctionState{state | inactive_bids: inactive_bids}
  end

  defp enter_auto_bids(state = %AuctionState{}, remaining_min_bids) do
    Enum.reduce(remaining_min_bids, state, fn bid, acc ->
      updated_bid = %AuctionBid{bid | id: UUID.uuid4(:hex)}

      acc
      |> invalidate_previous_auto_bids(updated_bid)
      |> invalidate_previous_bids(updated_bid)
      |> enter_bid(updated_bid)
      |> add_auto_bid(updated_bid)
    end)
  end

  defp decrement_auto_bids(state = %AuctionState{minimum_bids: []}), do: {state, []}

  defp decrement_auto_bids(state = %AuctionState{minimum_bids: min_bids, lowest_bids: []}) do
    min_bid_amounts =
      Enum.uniq_by(min_bids, & &1.min_amount)
      |> Enum.sort_by(& &1.min_amount)

    [first_lowest_min_bid | rest] = min_bid_amounts
    second_lowest_min_bid = Enum.at(rest, 0, nil)

    decremented_auto_bids =
      Enum.map(min_bids, fn bid = %AuctionBid{min_amount: min_amount} ->
        cond do
          min_amount == first_lowest_min_bid.min_amount && second_lowest_min_bid -> {bid, second_lowest_min_bid.min_amount - 0.25}

          true -> {bid, min_amount}
        end
      end)
      |> Enum.reject(fn ({bid, new_amount}) -> bid.amount == new_amount end)
      |> Enum.map(fn({bid, new_amount}) ->
        %AuctionBid{bid | amount: new_amount}
      end)
      |> Enum.sort_by(&{&1.amount, &1.time_entered})

    next_state = enter_auto_bids(state, decremented_auto_bids)

    events =
      Enum.map(decremented_auto_bids, fn bid ->
        AuctionEvent.auto_bid_placed(bid, next_state, nil)
      end)

    {next_state, events}
  end

  defp decrement_auto_bids(
         state = %AuctionState{minimum_bids: min_bids, lowest_bids: lowest_bids = [lowest_bid | _]}
       ) do
    min_bid_amounts =
      Enum.uniq_by(min_bids, & &1.min_amount)
      |> Enum.sort_by(& &1.min_amount)

    [first_lowest_min_bid | rest] = min_bid_amounts
    second_lowest_min_bid = Enum.at(rest, 0, nil)

    has_single_lowest_bid = Enum.count(lowest_bids, fn(bid) -> bid.amount == lowest_bid.amount end) == 1

    winning_bid_target =
      if second_lowest_min_bid do
        Enum.min([second_lowest_min_bid.min_amount, lowest_bid.amount])
      else
        lowest_bid.amount
      end

    decremented_auto_bids = set_decrements(
      min_bids,
      winning_bid_target,
      lowest_bid,
      has_single_lowest_bid,
      first_lowest_min_bid,
      second_lowest_min_bid
    )

    next_state = enter_auto_bids(state, decremented_auto_bids)

    events = decremented_auto_bids
    |> Enum.map(fn bid ->
        AuctionEvent.auto_bid_placed(bid, next_state, nil)
      end)

    {next_state, events}
  end

  defp set_decrements(auto_bids, winning_bid_target, lowest_bid, has_single_lowest_bid, first_lowest_min_bid, second_lowest_min_bid) do
    Enum.map(auto_bids, fn bid = %AuctionBid{min_amount: min_amount} ->
      is_already_leading =
        bid.supplier_id == lowest_bid.supplier_id &&
        bid.amount == winning_bid_target &&
        has_single_lowest_bid

      is_tied_leading =
        bid.supplier_id == lowest_bid.supplier_id &&
        bid.amount == winning_bid_target &&
        !has_single_lowest_bid

      cond do
        is_already_leading -> {bid, bid.amount}

        is_tied_leading && min_amount < lowest_bid.amount -> {bid, lowest_bid.amount - 0.25}

        min_amount >= lowest_bid.amount -> {bid, min_amount}

        min_amount == first_lowest_min_bid.min_amount -> {bid, winning_bid_target - 0.25}

        true -> {bid, min_amount}
      end
    end)
    |> Enum.reject(fn ({bid, new_amount}) -> bid.amount == new_amount end)
    |> Enum.map(fn({bid, new_amount}) ->
      %AuctionBid{bid | amount: new_amount}
    end)
    |> Enum.sort_by(&{&1.amount, &1.time_entered})
  end

  defp enter_bid(
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

  defp enter_bid(
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
    |> invalidate_previous_auto_bids(bid)
    |> invalidate_previous_bids(bid)
    |> add_auto_bid(bid)
    |> sort_lowest_bids
  end

  defp enter_bid(
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
    |> invalidate_previous_auto_bids(bid)
    |> invalidate_previous_bids(bid)
    |> add_bid(bid)
    |> sort_lowest_bids
  end

  defp add_bid(state = %AuctionState{bids: bids, active_bids: active_bids}, bid = %AuctionBid{}) do
    %AuctionState{state | bids: [bid | bids], active_bids: [bid | active_bids]}
  end

  defp add_auto_bid(
         state = %AuctionState{bids: _bids, minimum_bids: min_bids},
         bid = %AuctionBid{}
       ) do
    %AuctionState{state | minimum_bids: [bid | min_bids]}
  end

  defp sort_lowest_bids(state = %AuctionState{active_bids: active_bids}) do
    lowest_bids =
      active_bids
      |> Enum.sort_by(&{&1.amount, DateTime.to_unix(&1.time_entered, :microsecond)})

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
    {suppliers_old_bids, _others_bids} =
      Enum.split_with(active_bids, fn bid -> bid.supplier_id == supplier_id end)

    updated_bids =
      bids
      |> Enum.map(fn bid ->
        case bid in suppliers_old_bids do
          true -> %AuctionBid{bid | active: false}
          false -> bid
        end
      end)

    {active_bids, inactive_bids} = Enum.split_with(updated_bids, &(&1.active == true))

    %AuctionState{
      state
      | inactive_bids: inactive_bids,
        active_bids: active_bids,
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

    {active_bids, inactive_bids} = Enum.split_with(updated_bids, &(&1.active == true))

    %AuctionState{
      state
      | inactive_bids: inactive_bids,
        bids: updated_bids,
        active_bids: active_bids,
        minimum_bids: others_bids
    }
  end
end
