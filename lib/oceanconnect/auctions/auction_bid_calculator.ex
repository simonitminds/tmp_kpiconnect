defmodule Oceanconnect.Auctions.AuctionBidCalculator do
  alias Oceanconnect.Auctions.{AuctionBid, AuctionEvent}
  alias Oceanconnect.Auctions.AuctionStore.{AuctionState, ProductBidState}

  def process_all(auction_state = %AuctionState{}, :pending) do
    {auction_state, []}
  end

  def process_all(auction_state = %AuctionState{product_bids: product_bids}, status) do
    {new_auction_state, events} =
      product_bids
      |> Enum.reduce({auction_state, []}, fn({product_key, product_bid_state}, {auction_state, events}) ->
        {new_product_bid_state, new_events} = process(product_bid_state, status)

        new_auction_state =
          AuctionState.update_product_bids(auction_state, product_key, new_product_bid_state)

        {new_auction_state, events ++ new_events}
      end)

    {new_auction_state, events}
  end

  def process(
        current_state = %ProductBidState{},
        bid = %AuctionBid{min_amount: min_amount},
        status
      )
      when is_number(min_amount) do
    enter_auto_bid(current_state, bid, status)
    |> process(status)
  end

  def process(current_state = %ProductBidState{}, bid = %AuctionBid{}, status) do
    enter_bid(current_state, bid, status)
    |> process(status)
  end

  def process(current_state = %ProductBidState{}, :pending) do
    {current_state, []}
  end

  def process(
        current_state = %ProductBidState{
          auction_id: _auction_id,
          minimum_bids: [],
          bids: [],
          lowest_bids: [],
          active_bids: [],
          inactive_bids: []
        },
        _status
      ) do
    {current_state, []}
  end

  def process(
        current_state = %ProductBidState{
          auction_id: _auction_id,
          minimum_bids: _min_bids,
          bids: [],
          lowest_bids: [],
          active_bids: [],
          inactive_bids: []
        },
        :open
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
        current_state = %ProductBidState{
          auction_id: _auction_id,
          minimum_bids: _min_bids,
          bids: _bids,
          lowest_bids: _lowest_bids,
          active_bids: _active_bids,
          inactive_bids: _inactive_bids
        },
        :open
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

  def revoke_supplier_bids(state = %ProductBidState{}, supplier_id)
      when is_integer(supplier_id) do
    state
    |> invalidate_previous_auto_bids(supplier_id)
    |> invalidate_previous_bids(supplier_id)
    |> sort_lowest_bids()
  end

  defp enter_opening_bids(state = %ProductBidState{minimum_bids: [min_bid = %AuctionBid{}]}) do
    enter_auto_bid(state, min_bid, :open)
  end

  defp enter_opening_bids(state = %ProductBidState{minimum_bids: min_bids}) do
    enter_auto_bids(state, min_bids, :open)
  end

  defp enter_auto_bids(state = %ProductBidState{bids: bids}, [], _status) do
    # TODO I'm not super sure why I need to do this instead of just returning state

    inactive_bids = Enum.filter(bids, fn bid -> bid.active == false end)
    %ProductBidState{state | inactive_bids: inactive_bids}
  end

  defp enter_auto_bids(state = %ProductBidState{}, remaining_min_bids, status) do
    Enum.reduce(remaining_min_bids, state, fn bid, acc ->
      updated_bid = %AuctionBid{bid | id: UUID.uuid4(:hex), time_entered: DateTime.utc_now()}

      acc
      |> invalidate_previous_auto_bids(updated_bid)
      |> invalidate_previous_bids(updated_bid)
      |> enter_bid(updated_bid, status)
      |> add_auto_bid(updated_bid)
    end)
  end

  defp decrement_auto_bids(state = %ProductBidState{minimum_bids: []}), do: {state, []}

  defp decrement_auto_bids(state = %ProductBidState{minimum_bids: [min_bid], lowest_bids: []}) do
    updated_min_bid = %AuctionBid{min_bid | amount: min_bid.amount || min_bid.min_amount}
    next_state = enter_auto_bids(state, [updated_min_bid], :open)
    triggered_event = AuctionEvent.auto_bid_triggered(updated_min_bid, next_state)
    {next_state, [triggered_event]}
  end

  defp decrement_auto_bids(state = %ProductBidState{minimum_bids: min_bids, lowest_bids: []}) do
    min_bid_amounts = Enum.sort_by(min_bids, & &1.min_amount)

    [first_lowest_min_bid | rest] = min_bid_amounts
    second_lowest_min_bid = Enum.at(rest, 0, nil)

    decremented_auto_bids =
      Enum.map(min_bids, fn bid = %AuctionBid{amount: amount, min_amount: min_amount} ->
        cond do
          amount == min_amount ->
            {bid, amount}

          min_amount == first_lowest_min_bid.min_amount && second_lowest_min_bid ->
            {bid, max(second_lowest_min_bid.min_amount - 0.25, bid.min_amount)}

          true ->
            {bid, min_amount}
        end
      end)
      |> Enum.reject(fn {bid, new_amount} -> bid.amount == new_amount end)
      |> Enum.map(fn {bid, new_amount} ->
        %AuctionBid{bid | amount: min(bid.amount, new_amount)}
      end)
      |> sort_bids()

    next_state = enter_auto_bids(state, decremented_auto_bids, :open)

    events =
      Enum.map(decremented_auto_bids, fn bid ->
        AuctionEvent.auto_bid_triggered(bid, next_state)
      end)

    {next_state, events}
  end

  defp decrement_auto_bids(
         state = %ProductBidState{
           minimum_bids: min_bids,
           lowest_bids: lowest_bids = [lowest_bid | _]
         }
       ) do
    min_bid_amounts = Enum.sort_by(min_bids, & &1.min_amount)

    [first_lowest_min_bid | rest] = min_bid_amounts
    second_lowest_min_bid = Enum.at(rest, 0, nil)

    has_single_lowest_bid =
      Enum.count(lowest_bids, fn bid -> bid.amount == lowest_bid.amount end) == 1

    winning_bid_target =
      if second_lowest_min_bid do
        Enum.min([second_lowest_min_bid.min_amount, lowest_bid.amount])
      else
        lowest_bid.amount
      end

    decremented_auto_bids =
      set_decrements(
        min_bids,
        winning_bid_target,
        lowest_bid,
        has_single_lowest_bid,
        first_lowest_min_bid,
        second_lowest_min_bid
      )

    next_state = enter_auto_bids(state, decremented_auto_bids, :open)

    events =
      decremented_auto_bids
      |> Enum.map(fn bid ->
        AuctionEvent.auto_bid_triggered(bid, next_state)
      end)

    {next_state, events}
  end

  defp set_decrements(
         auto_bids,
         winning_bid_target,
         lowest_bid,
         has_single_lowest_bid,
         first_lowest_min_bid,
         _second_lowest_min_bid
       ) do
    Enum.map(auto_bids, fn bid = %AuctionBid{amount: amount, min_amount: min_amount} ->
      is_already_leading =
        bid.supplier_id == lowest_bid.supplier_id && bid.amount == winning_bid_target &&
          has_single_lowest_bid

      is_tied_leading =
        bid.supplier_id == lowest_bid.supplier_id && bid.amount == winning_bid_target &&
          !has_single_lowest_bid

      cond do
        is_already_leading ->
          {bid, amount || min_amount}

        is_tied_leading && min_amount < lowest_bid.amount ->
          {bid, max(lowest_bid.amount - 0.25, min_amount)}

        min_amount >= lowest_bid.amount ->
          {bid, min_amount}

        min_amount == first_lowest_min_bid.min_amount ->
          {bid, max(winning_bid_target - 0.25, min_amount)}

        true ->
          {bid, min_amount}
      end
    end)
    |> Enum.reject(fn {bid, new_amount} -> bid.amount == new_amount end)
    |> Enum.map(fn {bid, new_amount} ->
      %AuctionBid{bid | amount: min(bid.amount, new_amount)}
    end)
    |> sort_bids()
  end

  defp enter_auto_bid(
         current_state = %ProductBidState{lowest_bids: _lowest_bids},
         bid = %AuctionBid{amount: amount, min_amount: min_amount},
         :pending
       )
       when is_number(min_amount) and is_number(amount) do
    current_state
    |> invalidate_previous_auto_bids(bid)
    |> invalidate_previous_bids(bid)
    |> add_auto_bid(bid)
    |> add_bid(bid)
  end

  defp enter_auto_bid(
         current_state = %ProductBidState{lowest_bids: _lowest_bids},
         bid = %AuctionBid{min_amount: min_amount},
         :open
       )
       when is_number(min_amount) do
    bid = ensure_initial_auto_bid_amount(current_state, bid)

    current_state
    |> invalidate_previous_auto_bids(bid)
    |> invalidate_previous_bids(bid)
    |> add_auto_bid(bid)
  end

  defp ensure_initial_auto_bid_amount(
         _current_state,
         bid = %AuctionBid{amount: amount}
       )
       when is_number(amount) do
    bid
  end

  defp ensure_initial_auto_bid_amount(
         _current_state = %ProductBidState{lowest_bids: lowest_bids},
         bid = %AuctionBid{amount: nil, supplier_id: supplier_id}
       ) do
    existing_supplier_bid = Enum.find(lowest_bids, nil, &(&1.supplier_id == supplier_id))

    case existing_supplier_bid do
      nil -> bid
      %AuctionBid{amount: amount} -> %AuctionBid{bid | amount: amount}
    end
  end

  defp enter_bid(
         current_state = %ProductBidState{
           auction_id: auction_id
         },
         bid = %AuctionBid{
           auction_id: auction_id,
           amount: amount,
           min_amount: nil
         },
         :pending
       ) do
    current_state
    |> invalidate_previous_auto_bids(bid)
    |> invalidate_previous_bids(bid)
    |> add_bid(bid)
  end

  defp enter_bid(
         current_state = %ProductBidState{
           auction_id: auction_id
         },
         bid = %AuctionBid{
           auction_id: auction_id,
           min_amount: min_amount
         },
         :pending
       )
       when is_number(min_amount) do
    current_state
    |> invalidate_previous_auto_bids(bid)
    |> invalidate_previous_bids(bid)
    |> add_auto_bid(bid)
  end

  defp enter_bid(
         current_state = %ProductBidState{
           auction_id: auction_id,
           lowest_bids: [],
           minimum_bids: [],
           bids: []
         },
         bid = %AuctionBid{auction_id: auction_id},
         :open
       ) do
    %ProductBidState{current_state | bids: [bid], active_bids: [bid], lowest_bids: [bid]}
  end

  defp enter_bid(
         current_state = %ProductBidState{
           auction_id: auction_id,
           lowest_bids: [],
           minimum_bids: [],
           bids: []
         },
         bid = %AuctionBid{auction_id: auction_id},
         :open
       ) do
    %ProductBidState{current_state | bids: [bid], active_bids: [bid], lowest_bids: [bid]}
  end

  defp enter_bid(
         current_state = %ProductBidState{
           auction_id: auction_id
         },
         bid = %AuctionBid{
           auction_id: auction_id
         },
         status
       )
       when status in [:pending, :open] do
    current_state
    |> invalidate_previous_auto_bids(bid)
    |> invalidate_previous_bids(bid)
    |> add_bid(bid)
  end

  defp add_bid(
         state = %ProductBidState{bids: bids, active_bids: active_bids},
         bid = %AuctionBid{}
       ) do
    %ProductBidState{state | bids: [bid | bids], active_bids: [bid | active_bids]}
  end

  defp add_auto_bid(
         state = %ProductBidState{bids: _bids, minimum_bids: min_bids},
         bid = %AuctionBid{}
       ) do
    %ProductBidState{state | minimum_bids: [bid | min_bids]}
  end

  defp sort_lowest_bids(state = %ProductBidState{active_bids: active_bids}) do
    lowest_bids =
      active_bids
      |> sort_bids()

    %ProductBidState{state | lowest_bids: lowest_bids}
  end

  defp invalidate_previous_bids(state, %AuctionBid{supplier_id: supplier_id}) do
    invalidate_previous_bids(state, supplier_id)
  end

  defp invalidate_previous_bids(
         state = %ProductBidState{
           bids: bids,
           lowest_bids: _lowest_bids,
           active_bids: active_bids,
           inactive_bids: _inactive_bids
         },
         supplier_id
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

    %ProductBidState{
      state
      | inactive_bids: inactive_bids,
        active_bids: active_bids,
        bids: updated_bids
    }
  end

  defp invalidate_previous_auto_bids(state, %AuctionBid{supplier_id: supplier_id}) do
    invalidate_previous_auto_bids(state, supplier_id)
  end

  defp invalidate_previous_auto_bids(
         state = %ProductBidState{bids: bids, minimum_bids: min_bids},
         supplier_id
       ) do
    {suppliers_old_bids, others_bids} =
      Enum.split_with(min_bids, fn bid -> bid.supplier_id == supplier_id end)

    updated_bids =
      bids
      |> Enum.map(fn bid ->
        case bid in suppliers_old_bids do
          true -> %AuctionBid{bid | active: false}
          false -> bid
        end
      end)

    {active_bids, inactive_bids} = Enum.split_with(updated_bids, &(&1.active == true))

    %ProductBidState{
      state
      | inactive_bids: inactive_bids,
        bids: updated_bids,
        active_bids: active_bids,
        minimum_bids: others_bids
    }
  end

  defp sort_bids(bids) do
    bids
    |> Enum.sort_by(&{&1.amount, DateTime.to_unix(&1.original_time_entered, :microsecond)})
  end
end
