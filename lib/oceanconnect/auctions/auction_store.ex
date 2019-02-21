defmodule Oceanconnect.Auctions.AuctionStore do
  use GenServer
  import Oceanconnect.Auctions.Guards

  alias Oceanconnect.Auctions

  alias Oceanconnect.Auctions.{
    Auction,
    TermAuction,
    AuctionBarge,
    AuctionBid,
    AuctionCache,
    AuctionComment,
    AuctionEvent,
    AuctionEventStore,
    StoreProtocol,
    AuctionTimer,
    Command,
    Solution,
    AuctionStore.AuctionState,
    AuctionStore.TermAuctionState
  }

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

  def process_command(
    %Command{
      command: cmd,
      data: data = %{comment: %AuctionComment{auction_id: auction_id}}
    }
  ) do
    with {:ok, pid} <- find_pid(auction_id), do: GenServer.cast(pid, {cmd, data, true})
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

  def process_command(%Command{command: cmd, data: data = %{auction: %struct{id: auction_id}}})
      when is_auction(struct) do
    with {:ok, pid} <- find_pid(auction_id),
         do: GenServer.cast(pid, {cmd, data, true})
  end

  def process_command(%Command{command: cmd, data: auction = %struct{id: auction_id}})
      when is_auction(struct) do
    with {:ok, pid} <- find_pid(auction_id),
         do: GenServer.cast(pid, {cmd, auction, true})
  end

  # Server
  def init(auction = %Auction{id: auction_id}) do
    state =
      case replay_events(auction) do
        nil -> AuctionState.from_auction(auction)
        state -> maybe_emit_rebuilt_event(state)
      end

    AuctionCache.make_cache_available(auction_id)

    {:ok, state}
  end

  def init(auction = %TermAuction{id: auction_id}) do
    state =
      case replay_events(auction) do
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
        {:start_auction, %{auction: auction = %struct{}, user: user}, emit},
        current_state
      )
      when is_auction(struct) do
    new_state = StoreProtocol.start_auction(current_state, auction, user, emit)

    {:noreply, new_state}
  end

  def handle_cast({:update_auction, %{auction: auction, user: user}, emit}, current_state) do
    state = StoreProtocol.update_auction(current_state, auction, emit)

    AuctionEvent.emit(AuctionEvent.auction_updated(auction, user), emit)

    {:noreply, state}
  end

  def handle_cast(
        {:end_auction, auction = %struct{}, emit},
        current_state = %{status: :open}
      )
      when is_auction(struct) do
    new_state = StoreProtocol.end_auction(current_state, auction)

    AuctionEvent.emit(AuctionEvent.auction_ended(auction, new_state), emit)

    {:noreply, new_state}
  end

  def handle_cast({:end_auction, _auction, _emit}, current_state),
    do: {:noreply, current_state}

  def handle_cast(
        {:end_auction_decision_period, auction = %struct{}, emit},
        current_state
      )
      when is_auction(struct) do
    new_state = StoreProtocol.expire_auction(current_state, auction)

    AuctionEvent.emit(AuctionEvent.auction_expired(auction, new_state), emit)

    {:noreply, new_state}
  end

  def handle_cast(
        {:process_new_bid, %{bid: bid = %{min_amount: nil}, user: user}, emit},
        current_state = %{auction_id: auction_id}
      ) do
    {new_product_state, events, new_state} = StoreProtocol.process_bid(current_state, bid)
    Enum.map(events, &AuctionEvent.emit(&1, true))
    AuctionEvent.emit(AuctionEvent.bid_placed(bid, new_product_state, user), emit)

    if StoreProtocol.is_lowest_bid?(new_state, bid) or
         StoreProtocol.is_suppliers_first_bid?(current_state, bid) do
      maybe_emit_extend_auction(auction_id, AuctionTimer.extend_auction?(auction_id), emit)
    end

    {:noreply, new_state}
  end

  def handle_cast(
        {:process_new_bid, %{bid: bid = %{min_amount: _min_amount}, user: user}, emit},
        current_state = %{auction_id: auction_id}
      ) do
    {new_product_state, events, new_state} = StoreProtocol.process_bid(current_state, bid)
    AuctionEvent.emit(AuctionEvent.auto_bid_placed(bid, new_product_state, user), emit)
    Enum.map(events, &AuctionEvent.emit(&1, true))

    if StoreProtocol.is_lowest_bid?(new_state, bid) or
         StoreProtocol.is_suppliers_first_bid?(current_state, bid) do
      maybe_emit_extend_auction(auction_id, AuctionTimer.extend_auction?(auction_id), emit)
    end

    {:noreply, new_state}
  end

  def handle_cast(
        {:revoke_supplier_bids, %{product: product, supplier_id: supplier_id, user: user}, emit},
        current_state = %{auction_id: auction_id}
      ) do
    new_state = StoreProtocol.revoke_supplier_bids(current_state, product, supplier_id)

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
           auction: auction = %struct{},
           port_agent: port_agent,
           user: user
         }, emit},
        current_state
      ) when is_auction(struct) do
    new_state = StoreProtocol.select_winning_solution(current_state, solution, port_agent, auction)

    AuctionEvent.emit(
      AuctionEvent.winning_solution_selected(solution, port_agent, current_state, user),
      emit
    )

    AuctionEvent.emit(AuctionEvent.auction_closed(auction, new_state), emit)

    {:noreply, new_state}
  end

  def handle_cast(
    {:submit_comment, %{comment: comment, user: user}, emit},
    current_state
  ) do
    new_state = StoreProtocol.submit_comment(current_state, comment)

    AuctionEvent.emit(AuctionEvent.comment_submitted(comment, new_state, user), emit)

    {:noreply, new_state}
  end

  def handle_cast(
    {:unsubmit_comment, %{comment: comment, user: user}, emit},
    current_state
  ) do
    new_state = StoreProtocol.unsubmit_comment(current_state, comment)

    AuctionEvent.emit(AuctionEvent.comment_unsubmitted(comment, new_state, user), emit)

    {:noreply, new_state}
  end

  def handle_cast(
        {:submit_barge, %{auction_barge: auction_barge, user: user}, emit},
        current_state
      ) do
    new_state = StoreProtocol.submit_barge(current_state, auction_barge)

    AuctionEvent.emit(AuctionEvent.barge_submitted(auction_barge, new_state, user), emit)

    {:noreply, new_state}
  end

  def handle_cast(
        {:unsubmit_barge, %{auction_barge: auction_barge, user: user}, emit},
        current_state
      ) do
    new_state = StoreProtocol.unsubmit_barge(current_state, auction_barge)

    AuctionEvent.emit(AuctionEvent.barge_unsubmitted(auction_barge, new_state, user), emit)

    {:noreply, new_state}
  end

  def handle_cast(
        {:approve_barge, %{auction_barge: auction_barge, user: user}, emit},
        current_state
      ) do
    new_state = StoreProtocol.approve_barge(current_state, auction_barge)

    AuctionEvent.emit(AuctionEvent.barge_approved(auction_barge, new_state, user), emit)

    {:noreply, new_state}
  end

  def handle_cast(
        {:reject_barge, %{auction_barge: auction_barge, user: user}, emit},
        current_state
      ) do
    new_state = StoreProtocol.reject_barge(current_state, auction_barge)

    AuctionEvent.emit(AuctionEvent.barge_rejected(auction_barge, new_state, user), emit)

    {:noreply, new_state}
  end

  def handle_cast(
        {:cancel_auction, %{auction: auction = %struct{}, user: user}, emit},
        current_state
      )
      when is_auction(struct) do
    new_state = StoreProtocol.cancel_auction(current_state, auction)

    AuctionEvent.emit(AuctionEvent.auction_canceled(auction, new_state, user), emit)

    {:noreply, new_state}
  end

  def handle_cast({:notify_upcoming_auction, %{auction: auction = %struct{}}, emit}, state)
      when is_auction(struct) do
    AuctionEvent.emit(AuctionEvent.upcoming_auction_notified(auction), emit)
    {:noreply, state}
  end

  defp replay_events(auction = %struct{id: auction_id}) when is_auction(struct) do
    auction_id
    |> AuctionEventStore.event_list()
    |> Enum.reverse()
    |> Enum.reduce(nil, fn event, acc ->
      case replay_event(auction, event, acc) do
        nil -> acc
        result -> result
      end
    end)
  end

  defp replay_event(_auction,
         %AuctionEvent{type: :auction_created, data: auction = %Auction{}},
         _previous_state
       ) do
    auction = Auctions.fully_loaded(auction)
    AuctionState.from_auction(auction)
  end

  defp replay_event(_auction,
         %AuctionEvent{type: :auction_created, data: auction = %TermAuction{}},
         _previous_state
       ) do
    auction = Auctions.fully_loaded(auction)
    TermAuctionState.from_auction(auction)
  end

  defp replay_event(_auction,
         %AuctionEvent{type: :auction_started, data: %{state: state, auction: auction}},
         _previous_state
       ) do
    StoreProtocol.start_auction(state, auction, nil, false)
  end

  defp replay_event(_auction, %AuctionEvent{type: :auction_updated, data: auction}, previous_state) do
    StoreProtocol.update_auction(previous_state, auction, false)
  end

  defp replay_event(_auction, %AuctionEvent{type: :bid_placed, data: %{bid: event_bid}}, previous_state) do
    bid = AuctionBid.from_event_bid(event_bid)
    {_product_state, _events, new_state} = StoreProtocol.process_bid(previous_state, bid)
    new_state
  end

  defp replay_event(_auction,
         %AuctionEvent{type: :auto_bid_placed, data: %{bid: event_bid}},
         previous_state
       ) do
    bid = AuctionBid.from_event_bid(event_bid)
    {_product_state, _events, new_state} = StoreProtocol.process_bid(previous_state, bid)
    new_state
  end

  defp replay_event(_auction, %AuctionEvent{type: :auto_bid_triggered, data: %{bid: _bid}}, previous_state) do
    previous_state
  end

  defp replay_event(_auction,
         %AuctionEvent{type: :bids_revoked, data: %{product: product, supplier_id: supplier_id}},
         previous_state
       ) do
    StoreProtocol.revoke_supplier_bids(previous_state, product, supplier_id)
  end

  defp replay_event(_auction, %AuctionEvent{type: :duration_extended}, _previous_state), do: nil

  defp replay_event(_auction,
         %AuctionEvent{type: :auction_ended, data: %{auction: auction}},
         previous_state
       ) do
    StoreProtocol.end_auction(previous_state, auction)
  end

  defp replay_event(auction,
         %AuctionEvent{type: :auction_canceled, data: %{}},
         previous_state
       ) do
    StoreProtocol.cancel_auction(previous_state, auction)
  end

  defp replay_event(auction,
         %AuctionEvent{type: :winning_solution_selected, data: %{solution: solution, port_agent: port_agent}},
         previous_state
       ) do
    StoreProtocol.select_winning_solution(previous_state, solution, port_agent, auction)
  end

  defp replay_event(_auction,
         %AuctionEvent{type: :comment_submitted, data: %{comment: comment}},
         previous_state
       ) do
    StoreProtocol.submit_comment(previous_state, comment)
  end

  defp replay_event(_auction,
         %AuctionEvent{type: :comment_unsubmitted, data: %{comment: comment}},
         previous_state
       ) do
    StoreProtocol.unsubmit_comment(previous_state, comment)
  end

  defp replay_event(_auction,
         %AuctionEvent{type: :barge_submitted, data: %{auction_barge: auction_barge}},
         previous_state
       ) do
    StoreProtocol.submit_barge(previous_state, auction_barge)
  end

  defp replay_event(_auction,
         %AuctionEvent{type: :barge_unsubmitted, data: %{auction_barge: auction_barge}},
         previous_state
       ) do
    StoreProtocol.unsubmit_barge(previous_state, auction_barge)
  end

  defp replay_event(_auction,
         %AuctionEvent{type: :barge_approved, data: %{auction_barge: auction_barge}},
         previous_state
       ) do
    StoreProtocol.approve_barge(previous_state, auction_barge)
  end

  defp replay_event(_auction,
         %AuctionEvent{type: :barge_rejected, data: %{auction_barge: auction_barge}},
         previous_state
       ) do
    StoreProtocol.reject_barge(previous_state, auction_barge)
  end

  defp replay_event(auction, %AuctionEvent{type: :auction_expired}, previous_state) do
    StoreProtocol.expire_auction(previous_state, auction)
  end

  defp replay_event(_auction, %AuctionEvent{type: :auction_closed, data: %{state: state}}, _previous_state),
    do: state

  defp replay_event(_auction, %AuctionEvent{type: :auction_state_rebuilt, data: _state}, _previous_state),
    do: nil

  defp replay_event(_auction, _event, _previous_state), do: nil

  defp maybe_emit_rebuilt_event(state = %auction_state{status: :open, auction_id: auction_id})
       when is_auction_state(auction_state) do
    time_remaining = AuctionTimer.read_timer(auction_id, :duration)

    AuctionEvent.emit(AuctionEvent.auction_state_rebuilt(auction_id, state, time_remaining), true)

    state
  end

  defp maybe_emit_rebuilt_event(state = %auction_state{status: :decision, auction_id: auction_id})
       when is_auction_state(auction_state) do
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
