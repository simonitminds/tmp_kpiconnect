defmodule Oceanconnect.Auctions.AuctionStore do
  use GenServer
  import Oceanconnect.Auctions.Guards

  alias Oceanconnect.Auctions

  alias Oceanconnect.Auctions.{
    Auction,
    TermAuction,
    AuctionBarge,
    AuctionBid,
    AuctionBidCalculator,
    AuctionCache,
    AuctionEvent,
    AuctionEventStore,
    AuctionScheduler,
    Store,
    AuctionTimer,
    Command,
    SolutionCalculator,
    Solution
  }

  alias Oceanconnect.Auctions.{SpotAuctionState, TermAuctionState, ProductBidState}
  @registry_name :auctions_registry

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
  def start_link(auction = %struct{id: auction_id}) when is_auction(struct) do
    GenServer.start_link(__MODULE__, auction, name: get_auction_store_name(auction_id))
  end

  def get_current_state(%struct{id: auction_id}) when is_auction(struct) do
    with {:ok, pid} <- find_pid(auction_id),
         do: GenServer.call(pid, :get_current_state)
  end

  def process_command(%Command{
        command: cmd,
        data: data = %{bid: %AuctionBid{auction_id: auction_id}}
      }) do
    with {:ok, pid} <- find_pid(auction_id),
         do: GenServer.cast(pid, {cmd, data, true})
  end

  def process_command(%Command{
        command: :select_winning_solution,
        data: data = %{solution: %Solution{auction_id: auction_id}}
      }) do
    with {:ok, pid} <- find_pid(auction_id),
         do: GenServer.cast(pid, {:select_winning_solution, data, true})
  end

  def process_command(%Command{
        command: cmd,
        data: data = %{auction_barge: %AuctionBarge{auction_id: auction_id}}
      }) do
    with {:ok, pid} <- find_pid(auction_id),
         do: GenServer.cast(pid, {cmd, data, true})
  end

  def process_command(%Command{command: cmd, data: data = %{auction: %Auction{id: auction_id}}}) do
    with {:ok, pid} <- find_pid(auction_id),
         do: GenServer.cast(pid, {cmd, data, true})
  end

  def process_command(%Command{command: cmd, data: auction = %Auction{id: auction_id}}) do
    with {:ok, pid} <- find_pid(auction_id),
         do: GenServer.cast(pid, {cmd, auction, true})
  end

  # Server
  def init(auction = %Auction{id: auction_id}) do
    state =
      case replay_events(auction_id) do
        nil -> SpotAuctionState.from_auction(auction)
        state -> maybe_emit_rebuilt_event(state)
      end

    AuctionCache.make_cache_available(auction_id)

    {:ok, state}
  end

  def init(auction = %TermAuction{id: auction_id}) do
    state =
      case replay_events(auction_id) do
        nil -> TermAuctionState.from_auction(auction)
        state -> maybe_emit_rebuilt_event(state)
      end

    AuctionCache.make_cache_available(auction_id)

    {:ok, state}
  end

  def handle_call(:get_current_state, _from, current_state) do
    {:reply, current_state, current_state}
  end

  def handle_cast(
        {:start_auction, %{auction: auction = %Auction{}, user: user}, emit},
        current_state
      ) do
    new_state = Store.start_auction(current_state, auction, user, emit)

    {:noreply, new_state}
  end

  def handle_cast({:update_auction, %{auction: auction, user: user}, emit}, current_state) do
    state = Store.update_auction(current_state, auction, emit)

    AuctionEvent.emit(AuctionEvent.auction_updated(auction, user), emit)

    {:noreply, state}
  end

  def handle_cast(
        {:end_auction, auction = %Auction{}, emit},
        current_state = %{status: :open}
      ) do
    new_state = Store.end_auction(current_state, auction)

    AuctionEvent.emit(AuctionEvent.auction_ended(auction, new_state), emit)

    {:noreply, new_state}
  end

  def handle_cast({:end_auction, _auction, _emit}, current_state),
    do: {:noreply, current_state}

  def handle_cast(
        {:end_auction_decision_period, auction = %Auction{}, emit},
        current_state
      ) do
    new_state = Store.expire_auction(current_state)

    AuctionEvent.emit(AuctionEvent.auction_expired(auction, new_state), emit)

    {:noreply, new_state}
  end

  def handle_cast(
        {:process_new_bid, %{bid: bid = %{min_amount: nil}, user: user}, emit},
        current_state = %{auction_id: auction_id}
      ) do
    {new_product_state, events, new_state} = Store.process_bid(current_state, bid)
    Enum.map(events, &AuctionEvent.emit(&1, true))
    AuctionEvent.emit(AuctionEvent.bid_placed(bid, new_product_state, user), emit)

    if Store.is_lowest_bid?(new_state, bid) or Store.is_suppliers_first_bid?(current_state, bid) do
      maybe_emit_extend_auction(auction_id, AuctionTimer.extend_auction?(auction_id), emit)
    end

    {:noreply, new_state}
  end

  def handle_cast(
        {:process_new_bid, %{bid: bid = %{min_amount: _min_amount}, user: user}, emit},
        current_state = %{auction_id: auction_id}
      ) do
    {new_product_state, events, new_state} = Store.process_bid(current_state, bid)
    AuctionEvent.emit(AuctionEvent.auto_bid_placed(bid, new_product_state, user), emit)
    Enum.map(events, &AuctionEvent.emit(&1, true))

    if Store.is_lowest_bid?(new_state, bid) or Store.is_suppliers_first_bid?(current_state, bid) do
      maybe_emit_extend_auction(auction_id, AuctionTimer.extend_auction?(auction_id), emit)
    end

    {:noreply, new_state}
  end

  def handle_cast(
        {:revoke_supplier_bids, %{product: product, supplier_id: supplier_id, user: user}, emit},
        current_state = %{auction_id: auction_id}
      ) do
    new_state = Store.revoke_supplier_bids(current_state, product, supplier_id)

    AuctionEvent.emit(
      AuctionEvent.bids_revoked(auction_id, product, supplier_id, new_state, user),
      emit
    )

    {:noreply, new_state}
  end

  def handle_cast(
        {:select_winning_solution,
         %{
           solution: solution = %Solution{},
           auction: auction = %Auction{},
           port_agent: port_agent,
           user: user
         }, emit},
        current_state
      ) do
    new_state = Store.select_winning_solution(current_state, solution)

    AuctionEvent.emit(
      AuctionEvent.winning_solution_selected(solution, port_agent, current_state, user),
      emit
    )

    AuctionEvent.emit(AuctionEvent.auction_closed(auction, new_state), emit)

    {:noreply, new_state}
  end

  def handle_cast(
        {:submit_barge, %{auction_barge: auction_barge, user: user}, emit},
        current_state
      ) do
    new_state = Store.submit_barge(current_state, auction_barge)

    AuctionEvent.emit(AuctionEvent.barge_submitted(auction_barge, new_state, user), emit)

    {:noreply, new_state}
  end

  def handle_cast(
        {:unsubmit_barge, %{auction_barge: auction_barge, user: user}, emit},
        current_state
      ) do
    new_state = Store.unsubmit_barge(current_state, auction_barge)

    AuctionEvent.emit(AuctionEvent.barge_unsubmitted(auction_barge, new_state, user), emit)

    {:noreply, new_state}
  end

  def handle_cast(
        {:approve_barge, %{auction_barge: auction_barge, user: user}, emit},
        current_state
      ) do
    new_state = Store.approve_barge(current_state, auction_barge)

    AuctionEvent.emit(AuctionEvent.barge_approved(auction_barge, new_state, user), emit)

    {:noreply, new_state}
  end

  def handle_cast(
        {:reject_barge, %{auction_barge: auction_barge, user: user}, emit},
        current_state
      ) do
    new_state = Store.reject_barge(current_state, auction_barge)

    AuctionEvent.emit(AuctionEvent.barge_rejected(auction_barge, new_state, user), emit)

    {:noreply, new_state}
  end

  def handle_cast(
        {:cancel_auction, %{auction: auction = %Auction{}, user: user}, emit},
        current_state
      ) do
    new_state = Store.cancel_auction(current_state)

    AuctionEvent.emit(AuctionEvent.auction_canceled(auction, new_state, user), emit)
    {:noreply, new_state}
  end

  def handle_cast({:notify_upcoming_auction, %{auction: auction = %Auction{}}, emit}, state) do
    AuctionEvent.emit(AuctionEvent.upcoming_auction_notified(auction), emit)
    {:noreply, state}
  end

  defp replay_events(auction_id) do
    auction_id
    |> AuctionEventStore.event_list()
    |> Enum.reverse()
    |> Enum.reduce(nil, fn event, acc ->
      case replay_event(event, acc) do
        nil -> acc
        result -> result
      end
    end)
  end

  defp replay_event(%AuctionEvent{type: :auction_created, data: auction}, _previous_state) do
    auction = Auctions.fully_loaded(auction)
    Oceanconnect.Auctions.AuctionStore.AuctionState.from_auction(auction)
  end

  defp replay_event(
         %AuctionEvent{type: :auction_started, data: %{state: state, auction: auction}},
         _previous_state
       ) do
    Store.start_auction(state, auction, nil, false)
  end

  defp replay_event(%AuctionEvent{type: :auction_updated, data: auction}, previous_state) do
    Store.update_auction(auction, previous_state, false)
  end

  defp replay_event(%AuctionEvent{type: :bid_placed, data: %{bid: event_bid}}, previous_state) do
    bid = AuctionBid.from_event_bid(event_bid)
    {_product_state, _events, new_state} = Store.process_bid(previous_state, bid)
    new_state
  end

  defp replay_event(
         %AuctionEvent{type: :auto_bid_placed, data: %{bid: event_bid}},
         previous_state
       ) do
    bid = AuctionBid.from_event_bid(event_bid)
    {_product_state, _events, new_state} = Store.process_bid(previous_state, bid)
    new_state
  end

  defp replay_event(%AuctionEvent{type: :auto_bid_triggered, data: %{bid: _bid}}, previous_state) do
    previous_state
  end

  defp replay_event(
         %AuctionEvent{type: :bids_revoked, data: %{product: product, supplier_id: supplier_id}},
         previous_state
       ) do
    Store.revoke_supplier_bids(previous_state, product, supplier_id)
  end

  defp replay_event(%AuctionEvent{type: :duration_extended}, _previous_state), do: nil

  defp replay_event(
         %AuctionEvent{type: :auction_ended, data: %{auction: auction}},
         previous_state
       ) do
    Store.end_auction(previous_state, auction)
  end

  defp replay_event(
         %AuctionEvent{type: :auction_canceled, data: %{}},
         previous_state
       ) do
    Store.cancel_auction(previous_state)
  end

  defp replay_event(
         %AuctionEvent{type: :winning_solution_selected, data: %{solution: solution}},
         previous_state
       ) do
    Store.select_winning_solution(previous_state, solution)
  end

  defp replay_event(
         %AuctionEvent{type: :barge_submitted, data: %{auction_barge: auction_barge}},
         previous_state
       ) do
    Store.submit_barge(previous_state, auction_barge)
  end

  defp replay_event(
         %AuctionEvent{type: :barge_unsubmitted, data: %{auction_barge: auction_barge}},
         previous_state
       ) do
    Store.unsubmit_barge(previous_state, auction_barge)
  end

  defp replay_event(
         %AuctionEvent{type: :barge_approved, data: %{auction_barge: auction_barge}},
         previous_state
       ) do
    Store.approve_barge(previous_state, auction_barge)
  end

  defp replay_event(
         %AuctionEvent{type: :barge_rejected, data: %{auction_barge: auction_barge}},
         previous_state
       ) do
    Store.reject_barge(auction_barge, previous_state)
  end

  defp replay_event(%AuctionEvent{type: :auction_expired}, previous_state) do
    Store.expire_auction(previous_state)
  end

  defp replay_event(%AuctionEvent{type: :auction_closed, data: %{state: state}}, _previous_state),
    do: state

  defp replay_event(%AuctionEvent{type: :auction_state_rebuilt, data: _state}, _previous_state),
    do: nil

  defp replay_event(_event, _previous_state), do: nil

  defp maybe_emit_rebuilt_event(state = %{status: :open, auction_id: auction_id}) do
    time_remaining = AuctionTimer.read_timer(auction_id, :duration)

    AuctionEvent.emit(AuctionEvent.auction_state_rebuilt(auction_id, state, time_remaining), true)

    state
  end

  defp maybe_emit_rebuilt_event(state = %{status: :decision, auction_id: auction_id}) do
    time_remaining = AuctionTimer.read_timer(auction_id, :decision_duration)

    AuctionEvent.emit(AuctionEvent.auction_state_rebuilt(auction_id, state, time_remaining), true)

    state
  end

  defp maybe_emit_rebuilt_event(state), do: state

  defp maybe_emit_extend_auction(auction_id, {true, extension_time}, emit) do
    AuctionEvent.emit(AuctionEvent.duration_extended(auction_id, extension_time), emit)
  end

  defp maybe_emit_extend_auction(_auction_id, {false, _time_remaining}, _emit), do: nil
end
