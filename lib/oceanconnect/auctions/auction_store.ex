defmodule Oceanconnect.Auctions.AuctionStore do
  use GenServer
  alias Oceanconnect.Auctions.{Auction,
                               AuctionBidList,
                               AuctionCache,
                               AuctionEvent,
                               AuctionEventStore,
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

    def from_auction(auction_id) do
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
  def start_link(auction_id) do
    GenServer.start_link(__MODULE__, auction_id, name: get_auction_store_name(auction_id))
  end

  def get_current_state(%Auction{id: auction_id}) do
    with {:ok, pid} <- find_pid(auction_id),
      do: GenServer.call(pid, :get_current_state)
  end

  def process_command(%Command{command: cmd, data: data = %{auction_id: auction_id}}) do
    with {:ok, pid} <- find_pid(auction_id),
      do: GenServer.cast(pid, {cmd, data})
  end
  def process_command(%Command{command: cmd, data: data}) do
    with {:ok, pid} <- find_pid(data.id),
      do: GenServer.cast(pid, {cmd, data})
  end

   # Server
  def init(auction_id) do
    status = case rebuild_auction(auction_id) do
      nil -> :pending
      status -> status
    end

    state = auction_id
    |> AuctionState.from_auction
    |> Map.put(:status, status)
    AuctionCache.make_cache_available(auction_id)

    {:ok, state}
  end

  def handle_call(:get_current_state, _from, current_state) do
    {:reply, current_state, current_state}
  end

  def handle_cast({:start_auction, auction = %Auction{id: auction_id}}, current_state) do
    auction
    |> Command.start_duration_timer
    |> AuctionTimer.process_command

    new_state = %AuctionState{current_state | status: :open}

    AuctionEvent.emit(%AuctionEvent{type: :auction_started, auction_id: auction_id, data: new_state, time_entered: DateTime.utc_now()})

    {:noreply, new_state}
  end

  def handle_cast({:update_auction, auction = %Auction{}}, current_state) do
    AuctionEvent.emit(%AuctionEvent{type: :auction_updated, auction_id: auction.id, data: auction, time_entered: DateTime.utc_now()})

    {:noreply, current_state}
  end

  def handle_cast({:end_auction, auction = %Auction{id: auction_id}}, current_state = %{status: :open}) do
    auction
    |> Command.start_decision_duration_timer
    |> AuctionTimer.process_command

    new_state = %AuctionState{current_state | status: :decision}
    AuctionEvent.emit(%AuctionEvent{type: :auction_ended, auction_id: auction_id, data: new_state, time_entered: DateTime.utc_now()})

    {:noreply, new_state}
  end
  def handle_cast({:end_auction, _}, current_state), do: {:noreply, current_state}

  def handle_cast({:end_auction_decision_period, _data}, current_state = %{auction_id: auction_id}) do
    new_state = %AuctionState{current_state | status: :expired}
    AuctionEvent.emit(%AuctionEvent{type: :auction_decision_period_ended, auction_id: auction_id, data: new_state, time_entered: DateTime.utc_now()})
    {:noreply, new_state}
  end

  def handle_cast({:process_new_bid, bid = %{amount: amount}}, current_state = %{auction_id: auction_id, lowest_bids: lowest_bids}) do
    supplier_first_bid = bid
    |> Command.enter_bid
    |> AuctionBidList.process_command

    lowest_amount = case lowest_bids do
      [] -> nil
      _ -> hd(lowest_bids).amount
    end
    {lowest_bid, new_state} = set_lowest_bids?(bid, amount, current_state, lowest_amount)

    AuctionEvent.emit(%AuctionEvent{type: :bid_placed, auction_id: auction_id, data: bid, time_entered: bid.time_entered})
    if lowest_bid or supplier_first_bid do
      maybe_emit_extend_auction(auction_id, AuctionTimer.extend_auction?(auction_id))
    end
    {:noreply, new_state}
  end

  def handle_cast({:select_winning_bid, bid}, current_state = %{auction_id: auction_id}) do
    AuctionTimer.cancel_timer(auction_id, :decision_duration)

    new_state = current_state
    |> Map.put(:winning_bid, bid)
    |> Map.put(:status, :closed)

    AuctionEvent.emit(%AuctionEvent{type: :winning_bid_selected, auction_id: auction_id, data: new_state, time_entered: DateTime.utc_now()})
    AuctionEvent.emit(%AuctionEvent{type: :auction_closed, auction_id: auction_id, data: new_state, time_entered: DateTime.utc_now()})

    {:noreply, new_state}
  end

  defp maybe_emit_extend_auction(auction_id, {true, extension_time}) do
    AuctionEvent.emit(%AuctionEvent{type: :duration_extended, auction_id: auction_id, data: %{extension_time: extension_time}, time_entered: DateTime.utc_now()})
  end
  defp maybe_emit_extend_auction(_auction_id, {false, _time_remaining}), do: nil

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

  defp rebuild_auction(auction_id) do
    auction_id
    |> AuctionEventStore.event_list
    |> IO.inspect
    |> Enum.reduce(nil, fn(event, acc) ->
      acc = case replay_event(event) do
        :ok -> acc
        result -> result
      end
    end)
  end

  defp replay_event(%AuctionEvent{type: :auction_created, data: _auction}), do: :pending
  defp replay_event(%AuctionEvent{type: :auction_started, data: auction}) do
    GenServer.cast(self(), {:start_auction, auction})
    :open
  end
  defp replay_event(%AuctionEvent{type: :auction_updated, data: auction}) do
    GenServer.cast(self(), {:update_auction, auction})
  end
  defp replay_event(%AuctionEvent{type: :bid_placed, data: bid}) do
    GenServer.cast(self(), {:process_new_bid, bid})
  end
  defp replay_event(%AuctionEvent{type: :auction_ended, data: auction}) do
    GenServer.cast(self(), {:auction_ended, auction})
    :decision
  end
  defp replay_event(%AuctionEvent{type: :winning_bid_selected, data: bid}) do
    GenServer.cast(self(), {:select_winning_bid, bid})
    :closed
  end
  defp replay_event(%AuctionEvent{type: :auction_decision_period_ended, data: auction}) do
    GenServer.cast(self(), {:end_auction_decision_period, auction})
    :expired
  end
end
