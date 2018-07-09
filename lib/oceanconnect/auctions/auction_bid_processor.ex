defmodule Oceanconnect.Auctions.AuctionBidProcessor do
  alias Oceanconnect.Auctions.{AuctionBidList, AuctionEvent, Command}
  alias Oceanconnect.Auctions.AuctionStore.AuctionState

  def resolve_existing_bids(current_state = %{minimum_bids: minimum_bids}) do
    resolve_existing_bids(current_state, length(minimum_bids) < 2)
  end

  def resolve_existing_bids(current_state, true), do: current_state

  def resolve_existing_bids(
        current_state = %{lowest_bids: lowest_bids, minimum_bids: minimum_bids},
        _false
      ) do
    maybe_replace_lowest_bids(current_state, hd(lowest_bids), hd(minimum_bids), notify: true)
  end

  defp maybe_replace_lowest_bids(
         current_state = %{minimum_bids: minimum_bids},
         %{supplier_id: supplier_id},
         %{supplier_id: supplier_id},
         emit_events
       ) do
    [lowest_minimum_bid | remaining_bids] = minimum_bids
    time_entered = DateTime.utc_now()

    updated_lowest_bids =
      [lowest_minimum_bid | place_remaining_min_bids(remaining_bids, time_entered, emit_events)]
      |> resolve_lowest_bids
      |> maybe_resolve_matches

    Map.put(current_state, :lowest_bids, updated_lowest_bids)
  end

  # "opening bid maintains winning position",  "opening bid maintains winning position with auto_bid match"
  defp maybe_replace_lowest_bids(
         current_state = %{minimum_bids: minimum_bids},
         _lowest_bid,
         _lowest_min_bid,
         emit_events
       ) do
    updated_lowest_bids =
      minimum_bids
      |> place_auto_bids(emit_events)
      |> resolve_lowest_bids
      |> maybe_resolve_matches

    Map.put(current_state, :lowest_bids, updated_lowest_bids)
  end

  # "matched opening bid triggers minimum bid war"

  defp place_auto_bids(minimum_bids, emit_events) do
    [lowest_minimum_bid | remaining_bids] = minimum_bids
    time_entered = DateTime.utc_now()

    first_bid =
      case lowest_minimum_bid.min_amount == hd(remaining_bids).min_amount do
        true ->
          place_auto_bid(
            lowest_minimum_bid,
            lowest_minimum_bid.min_amount,
            time_entered,
            emit_events
          )

        _ ->
          place_auto_bid(
            lowest_minimum_bid,
            hd(remaining_bids).min_amount - 0.25,
            time_entered,
            emit_events
          )
      end

    [
      first_bid
      | Enum.map(remaining_bids, fn bid ->
          place_auto_bid(bid, bid.min_amount, time_entered, emit_events)
        end)
    ]
  end

  defp resolve_lowest_bids([lowest_bid | remaining_bids]) do
    [lowest_bid | Enum.reject(remaining_bids, fn bid -> bid.amount > lowest_bid.amount end)]
  end

  defp maybe_resolve_matches(lowest_bids = [lowest_bid | _remaining_bids]) do
    case length(lowest_bids) < 2 do
      true -> lowest_bids
      _ -> maybe_trigger_auto_bid(lowest_bid, lowest_bids)
    end
  end

  defp maybe_trigger_auto_bid(%{amount: amount, min_amount: amount}, lowest_bids), do: lowest_bids

  defp maybe_trigger_auto_bid(lowest_bid = %{amount: amount}, _lowest_bids) do
    [place_auto_bid(lowest_bid, amount - 0.25, DateTime.utc_now(), notify: true)]
  end

  # "auto_bid bid triggered on match to opening bid"

  def process_new_bid(bid, current_state = %{lowest_bids: lowest_bids}, emit_events \\ true) do
    supplier_first_bid? =
      bid
      |> Command.enter_bid()
      |> AuctionBidList.process_command()

    new_state = maybe_add_minimum_bid(current_state, bid)

    lowest_amount =
      case lowest_bids do
        [] -> nil
        _ -> hd(lowest_bids).amount
      end

    {lowest_bid?, updated_state} =
      maybe_set_lowest_bids(bid, new_state, lowest_amount, emit_events)

    {lowest_bid?, supplier_first_bid?, updated_state}
  end

  defp maybe_add_minimum_bid(
         current_state = %{minimum_bids: minimum_bids},
         bid = %{min_amount: _min_amount}
       ) do
    updated_minimum_bids =
      minimum_bids
      |> maybe_remove_existing_supplier_bid(bid)
      |> add_minimum_bid(bid)

    Map.put(current_state, :minimum_bids, updated_minimum_bids)
  end

  defp maybe_remove_existing_supplier_bid(minimum_bids, %{
         supplier_id: supplier_id,
         min_amount: min_amount
       }) do
    Enum.reject(minimum_bids, fn bid ->
      bid.supplier_id == supplier_id and bid.min_amount != min_amount
    end)
  end

  # "supplier can clear minimum bid"
  defp add_minimum_bid(minimum_bids, %{min_amount: min_amount})
       when is_nil(min_amount) or min_amount == "",
       do: minimum_bids

  defp add_minimum_bid([], bid), do: [bid]

  defp add_minimum_bid(minimum_bids, bid = %{supplier_id: supplier_id}) do
    add_minimum_bid(
      minimum_bids,
      bid,
      Enum.any?(minimum_bids, fn bid -> bid.supplier_id == supplier_id end)
    )
  end

  defp add_minimum_bid(minimum_bids, bid = %{min_amount: min_amount}, false) do
    case Enum.find_index(minimum_bids |> Enum.reverse(), fn x -> x.min_amount <= min_amount end) do
      nil -> [bid | minimum_bids]
      index -> List.insert_at(minimum_bids, index + 1, bid)
    end
  end

  defp add_minimum_bid(minimum_bids, _bid, _true), do: minimum_bids

  defp maybe_set_lowest_bids(
         bid = %{amount: nil, min_amount: min_amount},
         current_state,
         nil,
         emit_events
       ) do
    auto_bid = place_auto_bid(bid, min_amount, DateTime.utc_now(), emit_events)
    {true, %AuctionState{current_state | lowest_bids: [auto_bid]}}
  end

  # "bid with only minimum can be added"
  defp maybe_set_lowest_bids(
         %{amount: nil, supplier_id: supplier_id},
         current_state = %{lowest_bids: [%{supplier_id: supplier_id} | _]},
         _lowest_amount,
         _emit_events
       ) do
    {false, current_state}
  end

  # "supplier can change minimum with no bid"
  defp maybe_set_lowest_bids(
         bid = %{amount: nil, min_amount: min_amount},
         current_state,
         lowest_amount,
         emit_events
       )
       when min_amount > lowest_amount do
    place_auto_bid(bid, min_amount, DateTime.utc_now(), emit_events)
    {false, current_state}
  end

  # "auto_bid wins when only minimum provided"
  defp maybe_set_lowest_bids(
         bid = %{amount: nil, min_amount: amount, supplier_id: supplier_id},
         current_state = %{minimum_bids: minimum_bids},
         amount,
         emit_events
       ) do
    auto_bid = place_auto_bid(bid, amount, DateTime.utc_now(), emit_events)

    minimum_bids_without_current_supplier =
      Enum.reject(minimum_bids, fn bid -> bid.supplier_id == supplier_id end)

    maybe_resolve_minimum_bid(
      auto_bid,
      List.first(minimum_bids_without_current_supplier),
      current_state,
      amount,
      emit_events
    )
  end

  # "auto_bid triggered when new minimum only match placed"
  defp maybe_set_lowest_bids(
         bid = %{amount: nil, min_amount: min_amount},
         current_state,
         lowest_amount,
         emit_events
       )
       when min_amount < lowest_amount do
    auto_bid = place_auto_bid(bid, lowest_amount - 0.25, DateTime.utc_now(), emit_events)
    {true, %AuctionState{current_state | lowest_bids: [auto_bid]}}
  end

  # "auto_bid wins when only minimum provided"
  defp maybe_set_lowest_bids(bid, current_state, nil, _emit_events) do
    {true, %AuctionState{current_state | lowest_bids: [bid]}}
  end

  # "first bid is added to lowest_bids" there will always be a lowest bid if minimum bids exist
  defp maybe_set_lowest_bids(
         %{amount: amount, min_amount: nil},
         current_state,
         lowest_amount,
         _emit_events
       )
       when amount > lowest_amount do
    {false, current_state}
  end

  # "new higher bid with no minimum is not added"
  defp maybe_set_lowest_bids(
         bid = %{amount: amount},
         current_state = %{status: :pending},
         lowest_amount,
         _emit_events
       )
       when amount < lowest_amount do
    {true, %AuctionState{current_state | lowest_bids: [bid]}}
  end

  # "new lowest bid replaces existing"
  defp maybe_set_lowest_bids(
         bid = %{supplier_id: supplier_id},
         current_state = %{minimum_bids: minimum_bids},
         lowest_amount,
         emit_events
       ) do
    minimum_bids_without_current_supplier =
      Enum.reject(minimum_bids, fn bid -> bid.supplier_id == supplier_id end)

    maybe_resolve_minimum_bid(
      bid,
      List.first(minimum_bids_without_current_supplier),
      current_state,
      lowest_amount,
      emit_events
    )
  end

  defp maybe_set_lowest_bids(_bid, current_state, _lowest_amount, _emit_events),
    do: {false, current_state}

  defp maybe_resolve_minimum_bid(
         bid = %{min_amount: amount, time_entered: time_entered},
         nil,
         current_state = %{lowest_bids: lowest_bids},
         amount,
         emit_events
       ) do
    auto_bid = place_auto_bid(bid, amount, time_entered, emit_events)
    {false, %AuctionState{current_state | lowest_bids: lowest_bids ++ [auto_bid]}}
  end

  # "new higher bid with matching minimum is appended"
  defp maybe_resolve_minimum_bid(
         bid = %{amount: amount, min_amount: min_amount, time_entered: time_entered},
         nil,
         current_state,
         amount,
         emit_events
       )
       when min_amount < amount do
    auto_bid = place_auto_bid(bid, amount - 0.25, time_entered, emit_events)

    {true, %AuctionState{current_state | lowest_bids: [auto_bid]}}
  end

  # "new match to lowest bid with lower minimum replaces existing with auto_bid"
  defp maybe_resolve_minimum_bid(
         bid = %{amount: amount, min_amount: nil},
         nil,
         current_state = %{lowest_bids: lowest_bids},
         amount,
         _emit_events
       ) do
    {false, %AuctionState{current_state | lowest_bids: lowest_bids ++ [bid]}}
  end

  # "new match to lowest bid with no minimum is appended"
  defp maybe_resolve_minimum_bid(bid, nil, current_state, _lowest_amount, _emit_events) do
    {true, %AuctionState{current_state | lowest_bids: [bid]}}
  end

  # "new lower bid with minimum replaces existing"

  defp maybe_resolve_minimum_bid(
         bid = %{amount: amount},
         %{min_amount: min_amount},
         current_state,
         min_amount,
         _emit_events
       )
       when amount < min_amount do
    {true, %AuctionState{current_state | lowest_bids: [bid]}}
  end

  # "new lower bid beats minimum"
  defp maybe_resolve_minimum_bid(
         bid = %{amount: amount},
         %{min_amount: min_amount, time_entered: time_entered},
         current_state = %{minimum_bids: minimum_bids},
         _lowest_amount,
         emit_events
       )
       when amount < min_amount do
    place_remaining_min_bids(minimum_bids, time_entered, emit_events)
    {true, %AuctionState{current_state | lowest_bids: [bid]}}
  end

  # "lower bid with minimum triggers minimum bid war"
  defp maybe_resolve_minimum_bid(
         bid = %{amount: amount},
         %{min_amount: amount},
         current_state = %{lowest_bids: lowest_bids},
         amount,
         _emit_events
       ) do
    {false, %AuctionState{current_state | lowest_bids: lowest_bids ++ [bid]}}
  end

  # "minimum bid threshold is matched and min_bid supplier wins with auto_bid"
  defp maybe_resolve_minimum_bid(
         bid = %{amount: amount, time_entered: time_entered},
         min_bid = %{min_amount: amount},
         current_state,
         _lowest_amount,
         emit_events
       ) do
    auto_bid = place_auto_bid(min_bid, amount, time_entered, emit_events)
    {false, %AuctionState{current_state | lowest_bids: [auto_bid, bid]}}
  end

  # "minimum bid threshold is matched and min_bid supplier wins"
  defp maybe_resolve_minimum_bid(
         bid = %{amount: new_amount, min_amount: new_min_amount, time_entered: time_entered},
         min_bid = %{amount: old_amount, min_amount: old_min_amount},
         current_state,
         _lowest_amount,
         emit_events
       )
       when not is_nil(new_min_amount) and not is_nil(old_min_amount) do
    amount_to_bid =
      cond do
        new_min_amount && old_min_amount < new_min_amount && new_min_amount <= old_amount ->
          new_min_amount - 0.25

        old_min_amount < new_amount && new_amount <= old_amount ->
          new_amount - 0.25
      end

    other_bid = place_auto_bid(bid, new_min_amount, time_entered, emit_events)
    auto_bid = place_auto_bid(min_bid, amount_to_bid, time_entered, emit_events)

    if(other_bid.amount > auto_bid.amount) do
      {false, %AuctionState{current_state | lowest_bids: [auto_bid]}}
    else
      {false, %AuctionState{current_state | lowest_bids: [auto_bid, other_bid]}}
    end
  end

  # "matching bid triggers auto_bid",  "lower bid triggers auto_bid"
  defp maybe_resolve_minimum_bid(
         %{amount: new_amount, min_amount: nil, time_entered: time_entered},
         min_bid = %{amount: _old_amount, min_amount: _old_min_amount},
         current_state,
         _lowest_amount,
         emit_events
       ) do
    amount_to_bid = new_amount - 0.25
    auto_bid = place_auto_bid(min_bid, amount_to_bid, time_entered, emit_events)
    {false, %AuctionState{current_state | lowest_bids: [auto_bid]}}
  end

  # "matching bid triggers auto_bid",  "lower bid triggers auto_bid"
  defp maybe_resolve_minimum_bid(_bid, _min_bid, current_state, _lowest_amount) do
    {false, current_state}
  end

  defp place_auto_bid(bid, amount, time_entered, emit_events) do
    bid
    |> Map.put(:amount, amount)
    |> Map.put(:id, UUID.uuid4(:hex))
    |> Map.put(:time_entered, time_entered)
    |> process_auto_bid(emit_events)
  end

  defp process_auto_bid(bid, emit_events) do
    bid
    |> Command.enter_bid()
    |> AuctionBidList.process_command()

    if emit_events == true do
      AuctionEvent.emit(
        %AuctionEvent{
          type: :auto_bid_placed,
          auction_id: bid.auction_id,
          data: bid,
          time_entered: bid.time_entered,
          user: nil
        },
        true
      )
    end

    bid
  end

  defp place_remaining_min_bids(remaining_bids, time_entered, emit_events) do
    Enum.map(remaining_bids, fn bid ->
      place_auto_bid(bid, bid.min_amount, time_entered, emit_events)
    end)
  end
end
