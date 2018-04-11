defmodule Oceanconnect.Auctions.AuctionStore do
  use GenServer
  alias Oceanconnect.Auctions.{Auction,
                               AuctionEvent,
                               AuctionNotifier,
                               AuctionTimer,
                               Command,
                               TimersSupervisor}

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
    state = AuctionState.from_auction(auction_id)
    GenServer.start_link(__MODULE__, state, name: get_auction_store_name(auction_id))
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
  def init(auction_state) do
    state = Map.put(auction_state, :status, calculate_status(auction_state))
    {:ok, state}
  end

  def handle_call(:get_current_state, _from, current_state) do
    {:reply, current_state, current_state}
  end

  def handle_cast({:start_auction, %{id: auction_id, duration: duration}}, current_state) do
    # Get the current Auction State from current_state
    # process the start_auction command based on that state.
    case TimersSupervisor.start_timer({auction_id, duration, :duration}) do
      {:ok, pid} -> _timer_ref = AuctionTimer.get_timer(pid)
      error -> error
    end

    new_state = %AuctionState{current_state | status: :open}

    AuctionEvent.emit(%AuctionEvent{type: :auction_started, auction_id: auction_id, data: new_state})
    AuctionNotifier.notify_participants(new_state)

    # broadcast to the auction channel
    {:noreply, new_state}
  end

  def handle_cast({:end_auction, %{id: auction_id, decision_duration: decision_duration}}, current_state = %{status: :open}) do
    case TimersSupervisor.start_timer({auction_id, decision_duration, :decision_duration}) do
      {:ok, pid} -> _timer_ref = AuctionTimer.get_timer(pid)
      error -> error
    end
    new_state = %AuctionState{current_state | status: :decision}
    AuctionEvent.emit(%AuctionEvent{type: :auction_ended, auction_id: auction_id, data: new_state})
    AuctionNotifier.notify_participants(new_state)

    {:noreply, new_state}
  end
  def handle_cast({:end_auction, _}, current_state), do: {:noreply, current_state}

  def handle_cast({:end_auction_decision_period, _data}, current_state = %{auction_id: auction_id}) do
    new_state = %AuctionState{current_state | status: :expired}
    AuctionEvent.emit(%AuctionEvent{type: :auction_decision_period_ended, auction_id: auction_id, data: new_state})
    AuctionEvent.emit(%AuctionEvent{type: :auction_expired, auction_id: auction_id, data: new_state})
    AuctionNotifier.notify_participants(new_state)
    {:noreply, new_state}
  end

  def handle_cast({:process_new_bid, bid = %{amount: amount}}, current_state = %{lowest_bids: lowest_bids}) do
    lowest_amount = case lowest_bids do
      [] -> nil
      _ -> hd(lowest_bids).amount
    end
    new_state = set_lowest_bids?(bid, amount, current_state, lowest_amount)
    {:noreply, new_state}
  end

  def handle_cast({:select_winning_bid, bid}, current_state = %{auction_id: auction_id}) do
    AuctionTimer.cancel_timer(auction_id, :decision_duration)

    new_state = current_state
    |> Map.put(:winning_bid, bid)
    |> Map.put(:status, :closed)

    AuctionEvent.emit(%AuctionEvent{type: :winning_bid_selected, auction_id: auction_id, data: new_state})
    AuctionEvent.emit(%AuctionEvent{type: :auction_closed, auction_id: auction_id, data: new_state})
    AuctionNotifier.notify_participants(new_state)

    {:noreply, new_state}
  end

  defp set_lowest_bids?(bid, _amount, current_state, nil) do
    AuctionTimer.maybe_extend_auction(current_state.auction_id)
    %AuctionState{current_state | lowest_bids: [bid]}
  end
  defp set_lowest_bids?(bid, amount, current_state, lowest_amount) when lowest_amount > amount do
    AuctionTimer.maybe_extend_auction(current_state.auction_id)
    %AuctionState{current_state | lowest_bids: [bid]}
  end
  defp set_lowest_bids?(bid, amount, current_state = %{lowest_bids: lowest_bids}, amount) do
    AuctionTimer.maybe_extend_auction(current_state.auction_id)
    %AuctionState{current_state | lowest_bids: lowest_bids ++[bid]}
  end
  defp set_lowest_bids?(_bid, _amount, current_state, _lowest_amount), do: current_state

  defp calculate_status(_auction) do
    :pending
    # Go through event log
  end
end
