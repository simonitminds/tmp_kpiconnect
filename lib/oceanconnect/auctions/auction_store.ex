defmodule Oceanconnect.Auctions.AuctionStore do
  use GenServer
  alias Oceanconnect.Auctions.{Auction,
                               AuctionBidList,
                               AuctionCache,
                               AuctionEvent,
                               AuctionEventStore,
                               AuctionScheduler,
                               AuctionTimer,
                               Command}

  alias Oceanconnect.Auctions.AuctionStore.{AuctionState}

  @registry_name :auctions_registry

  defmodule AuctionState do
    alias __MODULE__
    defstruct auction_id: nil,
      status: :pending,
      lowest_bids: [],
      winning_bid: nil

    def from_auction(%Auction{id: auction_id, auction_start: nil}) do
      %AuctionState{
        auction_id: auction_id,
        status: :draft
      }
    end
    def from_auction(%Auction{id: auction_id}) do
      %AuctionState{
        auction_id: auction_id
      }
    end
  end

  def find_pid(auction_id) do
    with [{pid, _}] <- Registry.lookup(@registry_name, auction_id) do
      {:ok, pid}
    else
      [] -> {:error, "Auction Store Not Started"}
    end
  end

  defp get_auction_store_name(auction_id) do
    {:via, Registry, {@registry_name, auction_id}}
  end

  # Client
  def start_link(auction = %Auction{id: auction_id}) do
    GenServer.start_link(__MODULE__, auction, name: get_auction_store_name(auction_id))
  end

  def get_current_state(%Auction{id: auction_id}) do
    with {:ok, pid} <- find_pid(auction_id),
      do: GenServer.call(pid, :get_current_state)
  end

  def process_command(%Command{command: cmd, data: data = %{bid: %AuctionBidList.AuctionBid{auction_id: auction_id}}}) do
    with {:ok, pid} <- find_pid(auction_id),
      do: GenServer.cast(pid, {cmd, data, true})
  end
  def process_command(%Command{command: cmd, data: data = %{auction: %Auction{id: auction_id}}}) do
    with {:ok, pid} <- find_pid(auction_id),
      do: GenServer.cast(pid, {cmd, data, true})
  end
  def process_command(%Command{command: :end_auction, data: auction = %Auction{id: auction_id}}) do
    with {:ok, pid} <- find_pid(auction_id),
      do: GenServer.cast(pid, {:end_auction, auction, true})
  end
  def process_command(%Command{command: cmd, data: %Auction{id: auction_id}}) do
    with {:ok, pid} <- find_pid(auction_id),
      do: GenServer.cast(pid, {cmd, auction_id, true})
  end

  # Server
  def init(auction = %Auction{id: auction_id}) do
    state = case replay_events(auction_id) do
      nil -> AuctionState.from_auction(auction)
      state -> maybe_emit_rebuilt_event(state)
    end
    AuctionCache.make_cache_available(auction_id)

    {:ok, state}
  end

  def handle_call(:get_current_state, _from, current_state) do
    {:reply, current_state, current_state}
  end

  def handle_cast({:start_auction, %{auction: auction = %Auction{}, user: user}, emit}, current_state) do
    {new_state, updated_auction} = start_auction(current_state, auction)
    AuctionEvent.emit(%AuctionEvent{type: :auction_started, auction_id: auction.id, data: %{state: new_state, auction: updated_auction}, time_entered: updated_auction.auction_start, user: user}, emit)

    {:noreply, new_state}
  end

  def handle_cast({:update_auction, %{auction: auction, user: user}, emit}, current_state) do
    state = update_auction(auction, current_state)
    AuctionEvent.emit(%AuctionEvent{type: :auction_updated, auction_id: auction.id, data: auction, time_entered: DateTime.utc_now(), user: user}, emit)

    {:noreply, state}
  end

  def handle_cast({:end_auction, auction = %Auction{id: auction_id}, emit}, current_state = %{status: :open}) do
    {new_state, updated_auction} = end_auction(current_state, auction)
    AuctionEvent.emit(%AuctionEvent{type: :auction_ended, auction_id: auction_id, data: %{state: new_state, auction: updated_auction}, time_entered: updated_auction.auction_ended}, emit)

    {:noreply, new_state}
  end

  def handle_cast({:end_auction_decision_period, _data, emit}, current_state = %{auction_id: auction_id}) do
    new_state = expire_auction(current_state)
    AuctionEvent.emit(%AuctionEvent{type: :auction_expired, auction_id: auction_id, data: new_state, time_entered: DateTime.utc_now()}, emit)

    {:noreply, new_state}
  end
  def handle_cast({:end_auction, _auction_id, _emit}, current_state), do: {:noreply, current_state}

  def handle_cast({:process_new_bid, %{bid: bid, user: user}, emit}, current_state = %{auction_id: auction_id}) do
    {lowest_bid, supplier_first_bid, new_state} = process_new_bid(bid, current_state)
    AuctionEvent.emit(%AuctionEvent{type: :bid_placed, auction_id: auction_id, data: %{bid: bid, state: new_state}, time_entered: bid.time_entered, user: user}, emit)

    if lowest_bid or supplier_first_bid do
      maybe_emit_extend_auction(auction_id, AuctionTimer.extend_auction?(auction_id), emit)
    end
    {:noreply, new_state}
  end

  def handle_cast({:select_winning_bid, %{bid: bid, user: user}, emit}, current_state = %{auction_id: auction_id}) do
    new_state = select_winning_bid(bid, current_state)
    AuctionEvent.emit(%AuctionEvent{type: :winning_bid_selected, auction_id: auction_id, data: %{bid: bid, state: current_state}, time_entered: DateTime.utc_now(), user: user}, emit)
    AuctionEvent.emit(%AuctionEvent{type: :auction_closed, auction_id: auction_id, data: new_state, time_entered: DateTime.utc_now()}, emit)

    {:noreply, new_state}
  end

  defp replay_events(auction_id) do
    auction_id
    |> AuctionEventStore.event_list
    |> Enum.reverse
    |> Enum.reduce(nil, fn(event, acc) ->
      case replay_event(event, acc) do
        nil -> acc
        result -> result
      end
    end)
  end

  defp replay_event(%AuctionEvent{type: :auction_created}, _previous_state), do: nil
  defp replay_event(%AuctionEvent{type: :auction_started, data: %{state: state, auction: auction}}, _previous_state) do
    {new_state, _updated_auction} = start_auction(state, auction)
    new_state
  end
  defp replay_event(%AuctionEvent{type: :auction_updated, data: auction}, previous_state) do
    update_auction(auction, previous_state)
  end
  defp replay_event(%AuctionEvent{type: :bid_placed, data: %{bid: bid}}, previous_state) do
    {_lowest_bid, _supplier_first_bid, new_state} = process_new_bid(bid, previous_state)
    new_state
  end
  defp replay_event(%AuctionEvent{type: :duration_extended}, _previous_state), do: nil
  defp replay_event(%AuctionEvent{type: :auction_ended, data: %{auction: auction}}, previous_state) do
    {new_state, _updated_auction} = end_auction(previous_state, auction)
    new_state
  end
  defp replay_event(%AuctionEvent{type: :winning_bid_selected, data: %{bid: bid}}, previous_state) do
    select_winning_bid(bid, previous_state)
  end
  defp replay_event(%AuctionEvent{type: :auction_expired}, previous_state) do
    expire_auction(previous_state)
  end
  defp replay_event(%AuctionEvent{type: :auction_closed, data: state}, _previous_state), do: state
  defp replay_event(%AuctionEvent{type: :auction_state_rebuilt, data: _state}, _previous_state), do: nil
  defp replay_event(_event, _previous_state), do: nil

  defp start_auction(current_state = %{auction_id: auction_id}, auction = %Auction{}) do
    updated_auction = Map.put(auction, :auction_start, DateTime.utc_now())

    updated_auction
    |> Command.update_cache
    |> AuctionCache.process_command

    auction_id
    |> Command.start_duration_timer
    |> AuctionTimer.process_command

    auction_id
    |> Command.cancel_scheduled_start
    |> AuctionScheduler.process_command

    {%AuctionState{current_state | status: :open}, updated_auction}
  end

  defp update_auction(auction = %Auction{auction_start: start}, current_state = %{status: :draft}) when start != nil do
    update_auction_side_effects(auction)
    Map.put(current_state, :status, :pending)
  end
  defp update_auction(auction, current_state) do
    update_auction_side_effects(auction)
    current_state
  end

  defp update_auction_side_effects(auction) do
    auction
    |> Command.update_times
    |> AuctionTimer.process_command

    auction
    |> Command.update_cache
    |> AuctionCache.process_command

    auction
    |> Command.update_scheduled_start
    |> AuctionScheduler.process_command
  end

  defp end_auction(current_state = %{auction_id: auction_id}, auction = %Auction{}) do
    updated_auction = Map.put(auction, :auction_ended, DateTime.utc_now())

    updated_auction
    |> Command.update_cache
    |> AuctionCache.process_command

    auction_id
    |> Command.start_decision_duration_timer
    |> AuctionTimer.process_command

    {%AuctionState{current_state | status: :decision}, updated_auction}
  end

  defp process_new_bid(bid = %{amount: amount}, current_state = %{lowest_bids: lowest_bids}) do
    supplier_first_bid = bid
    |> Command.enter_bid
    |> AuctionBidList.process_command

    lowest_amount = case lowest_bids do
      [] -> nil
      _ -> hd(lowest_bids).amount
    end
    {lowest_bid, new_state} = set_lowest_bids?(bid, amount, current_state, lowest_amount)
    {lowest_bid, supplier_first_bid, new_state}
  end

  defp select_winning_bid(bid, current_state = %{auction_id: auction_id}) do
    AuctionTimer.cancel_timer(auction_id, :decision_duration)

    current_state
    |> Map.put(:winning_bid, bid)
    |> Map.put(:status, :closed)
  end

  defp expire_auction(current_state = %{auction_id: auction_id}) do
    AuctionTimer.cancel_timer(auction_id, :decision_duration)
    %AuctionState{current_state | status: :expired}
  end

  defp maybe_emit_rebuilt_event(state = %AuctionState{status: :open, auction_id: auction_id}) do
    time_remaining = AuctionTimer.read_timer(auction_id, :duration)
    AuctionEvent.emit(%AuctionEvent{type: :auction_state_rebuilt, data: %{state: state, time_remaining: time_remaining}, time_entered: DateTime.utc_now(), auction_id: auction_id}, true)
    state
  end
  defp maybe_emit_rebuilt_event(state = %AuctionState{status: :decision, auction_id: auction_id}) do
    time_remaining = AuctionTimer.read_timer(auction_id, :decision_duration)
    AuctionEvent.emit(%AuctionEvent{type: :auction_state_rebuilt, data: %{state: state, time_remaining: time_remaining}, time_entered: DateTime.utc_now(), auction_id: auction_id}, true)
    state
  end

  defp maybe_emit_rebuilt_event(state), do: state

  defp maybe_emit_extend_auction(auction_id, {true, extension_time}, emit) do
    AuctionEvent.emit(%AuctionEvent{type: :duration_extended, auction_id: auction_id, data: %{extension_time: extension_time}, time_entered: DateTime.utc_now()}, emit)
  end
  defp maybe_emit_extend_auction(_auction_id, {false, _time_remaining}, _emit), do: nil

  defp set_lowest_bids?(bid, _amount, current_state, nil) do
    {true, %AuctionState{current_state | lowest_bids: [bid]}}
  end
  defp set_lowest_bids?(bid, amount, current_state, lowest_amount) when lowest_amount > amount do
    {true, %AuctionState{current_state | lowest_bids: [bid]}}
  end
  defp set_lowest_bids?(bid, amount, current_state = %{lowest_bids: lowest_bids}, amount) do
    {true, %AuctionState{current_state | lowest_bids: lowest_bids ++[bid]}}
  end
  defp set_lowest_bids?(_bid, _amount, current_state, _lowest_amount), do: {false, current_state}
end
