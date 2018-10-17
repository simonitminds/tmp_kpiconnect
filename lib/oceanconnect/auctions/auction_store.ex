defmodule Oceanconnect.Auctions.AuctionStore do
  use GenServer

  alias Oceanconnect.Auctions

  alias Oceanconnect.Auctions.{
    Auction,
    AuctionBarge,
    AuctionBid,
    AuctionBidCalculator,
    AuctionCache,
    AuctionEvent,
    AuctionEventStore,
    AuctionScheduler,
    AuctionTimer,
    Command,
    Fuel,
    SolutionCalculator,
    Solution
  }

  alias Oceanconnect.Auctions.AuctionStore.{AuctionState, ProductBidState}
  @registry_name :auctions_registry

  defmodule ProductBidState do
    alias __MODULE__

    defstruct auction_id: nil,
              fuel_id: nil,
              lowest_bids: [],
              minimum_bids: [],
              bids: %{},
              active_bids: [],
              inactive_bids: []

    def for_product(fuel_id, auction_id) do
      %__MODULE__{
        auction_id: auction_id,
        fuel_id: fuel_id
      }
    end
  end

  defmodule AuctionState do
    alias __MODULE__

    defstruct auction_id: nil,
              status: :pending,
              solutions: %SolutionCalculator{},
              submitted_barges: [],
              product_bids: %{},
              winning_solution: nil

    def from_auction(%Auction{id: auction_id, scheduled_start: nil}) do
      %AuctionState{
        auction_id: auction_id,
        status: :draft
      }
    end

    def from_auction(%Auction{id: auction_id, fuels: fuels}) do
      product_bids =
        Enum.reduce(fuels, %{}, fn %Fuel{id: fuel_id}, acc ->
          Map.put(acc, "#{fuel_id}", ProductBidState.for_product(fuel_id, auction_id))
        end)

      %AuctionState{
        auction_id: auction_id,
        product_bids: product_bids
      }
    end

    def update_product_bids(state, product_key, new_product_state) do
      %AuctionState{
        state
        | product_bids: Map.put(state.product_bids, "#{product_key}", new_product_state)
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
    state =
      case replay_events(auction_id) do
        nil -> AuctionState.from_auction(auction)
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
    new_state = start_auction(current_state, auction)

    AuctionEvent.emit(AuctionEvent.auction_started(auction, new_state, user), emit)

    {:noreply, new_state}
  end

  def handle_cast({:update_auction, %{auction: auction, user: user}, emit}, current_state) do
    state = update_auction(auction, current_state)

    AuctionEvent.emit(AuctionEvent.auction_updated(auction, user), emit)

    {:noreply, state}
  end

  def handle_cast(
        {:end_auction, auction = %Auction{}, emit},
        current_state = %{status: :open}
      ) do
    new_state = end_auction(current_state, auction)

    AuctionEvent.emit(AuctionEvent.auction_ended(auction, new_state), emit)

    {:noreply, new_state}
  end

  def handle_cast({:end_auction, _auction_id, _emit}, current_state),
    do: {:noreply, current_state}

  def handle_cast(
        {:end_auction_decision_period, _data, emit},
        current_state = %{auction_id: auction_id}
      ) do
    new_state = expire_auction(current_state)

    AuctionEvent.emit(AuctionEvent.auction_expired(auction_id, new_state), emit)

    {:noreply, new_state}
  end

  def handle_cast(
        {:process_new_bid, %{bid: bid = %{min_amount: nil}, user: user}, emit},
        current_state = %{auction_id: auction_id}
      ) do
    {new_product_state, events, new_state} = process_bid(current_state, bid)
    Enum.map(events, &AuctionEvent.emit(&1, true))
    AuctionEvent.emit(AuctionEvent.bid_placed(bid, new_product_state, user), emit)

    if is_lowest_bid?(new_state, bid) or is_suppliers_first_bid?(current_state, bid) do
      maybe_emit_extend_auction(auction_id, AuctionTimer.extend_auction?(auction_id), emit)
    end

    {:noreply, new_state}
  end

  def handle_cast(
        {:process_new_bid, %{bid: bid = %{min_amount: _min_amount}, user: user}, emit},
        current_state = %{auction_id: auction_id}
      ) do
    {new_product_state, events, new_state} = process_bid(current_state, bid)
    AuctionEvent.emit(AuctionEvent.auto_bid_placed(bid, new_product_state, user), emit)
    Enum.map(events, &AuctionEvent.emit(&1, true))

    if is_lowest_bid?(new_state, bid) or is_suppliers_first_bid?(current_state, bid) do
      maybe_emit_extend_auction(auction_id, AuctionTimer.extend_auction?(auction_id), emit)
    end

    {:noreply, new_state}
  end

  def handle_cast(
        {:select_winning_solution, %{solution: solution = %Solution{}, user: user}, emit},
        current_state = %{auction_id: auction_id}
      ) do
    new_state = select_winning_solution(solution, current_state)

    AuctionEvent.emit(AuctionEvent.winning_solution_selected(solution, current_state, user), emit)
    AuctionEvent.emit(AuctionEvent.auction_closed(auction_id, new_state), emit)

    {:noreply, new_state}
  end

  def handle_cast(
        {:submit_barge, %{auction_barge: auction_barge, user: user}, emit},
        current_state
      ) do
    new_state = submit_barge(auction_barge, current_state)

    AuctionEvent.emit(AuctionEvent.barge_submitted(auction_barge, new_state, user), emit)

    {:noreply, new_state}
  end

  def handle_cast(
        {:unsubmit_barge, %{auction_barge: auction_barge, user: user}, emit},
        current_state
      ) do
    new_state = unsubmit_barge(auction_barge, current_state)

    AuctionEvent.emit(AuctionEvent.barge_unsubmitted(auction_barge, new_state, user), emit)

    {:noreply, new_state}
  end

  def handle_cast(
        {:approve_barge, %{auction_barge: auction_barge, user: user}, emit},
        current_state
      ) do
    new_state = approve_barge(auction_barge, current_state)

    AuctionEvent.emit(AuctionEvent.barge_approved(auction_barge, new_state, user), emit)

    {:noreply, new_state}
  end

  def handle_cast(
        {:reject_barge, %{auction_barge: auction_barge, user: user}, emit},
        current_state
      ) do
    new_state = reject_barge(auction_barge, current_state)

    AuctionEvent.emit(AuctionEvent.barge_rejected(auction_barge, new_state, user), emit)

    {:noreply, new_state}
  end

  def handle_cast(
        {:cancel_auction, %{auction: auction = %Auction{}, user: user}, emit},
        current_state
      ) do
    new_state = cancel_auction(current_state)

    AuctionEvent.emit(AuctionEvent.auction_canceled(auction, new_state, user), emit)
    {:noreply, new_state}
  end

  def handle_cast({:notify_upcoming_auction, %{auction: auction = %Auction{}}, emit}, state) do
    AuctionEvent.emit(AuctionEvent.upcoming_auction_notified(auction), emit)
    {:noreply, state}
  end

  defp is_suppliers_first_bid?(%AuctionState{product_bids: product_bids}, %AuctionBid{
         supplier_id: supplier_id
       }) do
    !Enum.any?(
      product_bids,
      fn {_product_key, %ProductBidState{bids: bids}} ->
        Enum.any?(bids, fn bid -> bid.supplier_id == supplier_id end)
      end
    )
  end

  defp is_lowest_bid?(
         %AuctionState{product_bids: product_bids},
         bid = %AuctionBid{fuel_id: fuel_id}
       ) do
    product_bids = product_bids[fuel_id]

    length(product_bids.lowest_bids) == 0 ||
      hd(product_bids.lowest_bids).supplier_id == bid.supplier_id
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
    start_auction(state, auction)
  end

  defp replay_event(%AuctionEvent{type: :auction_updated, data: auction}, previous_state) do
    update_auction(auction, previous_state)
  end

  defp replay_event(%AuctionEvent{type: :bid_placed, data: %{bid: bid}}, previous_state) do
    {_product_state, _events, new_state} = process_bid(previous_state, bid)
    new_state
  end

  defp replay_event(%AuctionEvent{type: :auto_bid_placed, data: %{bid: bid}}, previous_state) do
    {_product_state, _events, new_state} = process_bid(previous_state, bid)
    new_state
  end

  defp replay_event(%AuctionEvent{type: :auto_bid_triggered, data: %{bid: _bid}}, previous_state) do
    previous_state
  end

  defp replay_event(%AuctionEvent{type: :duration_extended}, _previous_state), do: nil

  defp replay_event(
         %AuctionEvent{type: :auction_ended, data: %{auction: auction}},
         previous_state
       ) do
    end_auction(previous_state, auction)
  end

  defp replay_event(%AuctionEvent{type: :winning_solution_selected, data: %{solution: solution}}, previous_state) do
    select_winning_solution(solution, previous_state)
  end

  defp replay_event(
         %AuctionEvent{type: :barge_submitted, data: %{auction_barge: auction_barge}},
         previous_state
       ) do
    submit_barge(auction_barge, previous_state)
  end

  defp replay_event(
         %AuctionEvent{type: :barge_unsubmitted, data: %{auction_barge: auction_barge}},
         previous_state
       ) do
    unsubmit_barge(auction_barge, previous_state)
  end

  defp replay_event(
         %AuctionEvent{type: :barge_approved, data: %{auction_barge: auction_barge}},
         previous_state
       ) do
    approve_barge(auction_barge, previous_state)
  end

  defp replay_event(
         %AuctionEvent{type: :barge_rejected, data: %{auction_barge: auction_barge}},
         previous_state
       ) do
    reject_barge(auction_barge, previous_state)
  end

  defp replay_event(%AuctionEvent{type: :auction_expired}, previous_state) do
    expire_auction(previous_state)
  end

  defp replay_event(%AuctionEvent{type: :auction_closed, data: state}, _previous_state), do: state

  defp replay_event(%AuctionEvent{type: :auction_state_rebuilt, data: _state}, _previous_state),
    do: nil

  defp replay_event(_event, _previous_state), do: nil

  defp start_auction(current_state, auction = %Auction{}) do
    auction
    |> Command.update_cache()
    |> AuctionCache.process_command()

    auction
    |> Command.start_duration_timer()
    |> AuctionTimer.process_command()

    auction
    |> Command.cancel_scheduled_start()
    |> AuctionScheduler.process_command()

    {next_state, _} =
      %AuctionState{current_state | status: :open}
      |> AuctionBidCalculator.process_all(:open)

    next_state = SolutionCalculator.process(next_state, auction)

    next_state
  end

  defp update_auction(
         auction = %Auction{scheduled_start: start},
         current_state = %{status: :draft}
       )
       when start != nil do
    update_auction_side_effects(auction)
    Map.put(current_state, :status, :pending)
  end

  defp update_auction(auction, current_state) do
    update_auction_side_effects(auction)
    current_state
  end

  defp update_auction_side_effects(auction) do
    auction
    |> Command.update_cache()
    |> AuctionCache.process_command()

    auction
    |> Command.update_scheduled_start()
    |> AuctionScheduler.process_command()
  end

  defp end_auction(current_state, auction = %Auction{}) do
    auction
    |> Command.update_cache()
    |> AuctionCache.process_command()

    auction
    |> Command.start_decision_duration_timer()
    |> AuctionTimer.process_command()

    %AuctionState{current_state | status: :decision}
  end

  defp process_bid(
         current_state = %{auction_id: auction_id, status: status, product_bids: product_bids},
         bid = %{fuel_id: fuel_id}
       ) do
    product_state = product_bids[fuel_id] || ProductBidState.for_product(fuel_id, auction_id)
    {new_product_state, events} = AuctionBidCalculator.process(product_state, bid, status)
    new_state = AuctionState.update_product_bids(current_state, fuel_id, new_product_state)

    # TODO: Not this
    auction = Auctions.get_auction!(auction_id) |> Auctions.fully_loaded()
    new_state = SolutionCalculator.process(new_state, auction)
    {new_product_state, events, new_state}
  end

  defp select_winning_solution(solution = %Solution{}, current_state = %{auction_id: auction_id}) do
    AuctionTimer.cancel_timer(auction_id, :decision_duration)

    current_state
    |> Map.put(:winning_solution, solution)
    |> Map.put(:status, :closed)
  end

  defp submit_barge(
         auction_barge = %AuctionBarge{
           auction_id: auction_id,
           barge_id: barge_id,
           supplier_id: supplier_id
         },
         current_state = %AuctionState{submitted_barges: submitted_barges}
       ) do
    barge_is_submitted =
      Enum.any?(submitted_barges, fn barge ->
        match?(
          %AuctionBarge{auction_id: ^auction_id, barge_id: ^barge_id, supplier_id: ^supplier_id},
          barge
        )
      end)

    if barge_is_submitted do
      current_state
    else
      %AuctionState{current_state | submitted_barges: submitted_barges ++ [auction_barge]}
    end
  end

  defp unsubmit_barge(
         %AuctionBarge{
           auction_id: auction_id,
           barge_id: barge_id,
           supplier_id: supplier_id
         },
         current_state = %AuctionState{submitted_barges: submitted_barges}
       ) do
    new_submitted_barges =
      Enum.reject(submitted_barges, fn barge ->
        match?(
          %AuctionBarge{auction_id: ^auction_id, barge_id: ^barge_id, supplier_id: ^supplier_id},
          barge
        )
      end)

    %AuctionState{current_state | submitted_barges: new_submitted_barges}
  end

  defp approve_barge(
         auction_barge = %AuctionBarge{
           auction_id: auction_id,
           barge_id: barge_id,
           supplier_id: supplier_id,
           approval_status: "APPROVED"
         },
         current_state = %AuctionState{submitted_barges: submitted_barges}
       ) do
    new_submitted_barges =
      Enum.map(submitted_barges, fn barge ->
        case barge do
          %AuctionBarge{auction_id: ^auction_id, barge_id: ^barge_id, supplier_id: ^supplier_id} ->
            auction_barge

          _ ->
            barge
        end
      end)

    %AuctionState{current_state | submitted_barges: new_submitted_barges}
  end

  defp reject_barge(
         auction_barge = %AuctionBarge{
           auction_id: auction_id,
           barge_id: barge_id,
           supplier_id: supplier_id,
           approval_status: "REJECTED"
         },
         current_state = %AuctionState{submitted_barges: submitted_barges}
       ) do
    new_submitted_barges =
      Enum.map(submitted_barges, fn barge ->
        case barge do
          %AuctionBarge{auction_id: ^auction_id, barge_id: ^barge_id, supplier_id: ^supplier_id} ->
            auction_barge

          _ ->
            barge
        end
      end)

    %AuctionState{current_state | submitted_barges: new_submitted_barges}
  end

  defp cancel_auction(current_state = %{auction_id: auction_id}) do
    AuctionTimer.cancel_timer(auction_id, :duration)
    AuctionTimer.cancel_timer(auction_id, :decision_duration)
    %AuctionState{current_state | status: :canceled}
  end

  defp expire_auction(current_state = %{auction_id: auction_id}) do
    AuctionTimer.cancel_timer(auction_id, :decision_duration)
    %AuctionState{current_state | status: :expired}
  end

  defp maybe_emit_rebuilt_event(state = %AuctionState{status: :open, auction_id: auction_id}) do
    time_remaining = AuctionTimer.read_timer(auction_id, :duration)

    AuctionEvent.emit(AuctionEvent.auction_state_rebuilt(auction_id, state, time_remaining), true)

    state
  end

  defp maybe_emit_rebuilt_event(state = %AuctionState{status: :decision, auction_id: auction_id}) do
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
