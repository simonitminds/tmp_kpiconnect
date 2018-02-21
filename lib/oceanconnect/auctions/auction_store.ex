defmodule Oceanconnect.Auctions.AuctionStore do
  use GenServer
  alias Oceanconnect.Auctions.{Auction, AuctionNotifier, AuctionTimer, TimersSupervisor}
  alias Oceanconnect.Auctions.AuctionStore.{AuctionCommand, AuctionState}

  @registry_name :auctions_registry

  defmodule AuctionState do
    alias __MODULE__
    defstruct auction_id: nil, status: :pending, current_server_time: nil, time_remaining: nil, buyer_id: nil, supplier_ids: []

    def from_auction(auction) do
      %AuctionState{auction_id: auction.id, buyer_id: auction.buyer.id, supplier_ids: Enum.map(auction.suppliers, &(&1.id))}
    end

    def maybe_update_times(auction_state = %AuctionState{status: :open, auction_id: auction_id}) do
      time_remaining = Process.read_timer(AuctionTimer.timer_ref(auction_id, :duration))
      update_times(auction_state, time_remaining)
    end
    def maybe_update_times(auction_state = %AuctionState{status: :decision, auction_id: auction_id}) do
      time_remaining = Process.read_timer(AuctionTimer.timer_ref(auction_id, :decision_duration))
      update_times(auction_state, time_remaining)
    end
    def maybe_update_times(auction_state), do: auction_state

    defp update_times(auction_state, time_remaining) do
      auction_state
      |> Map.put(:time_remaining, time_remaining)
      |> Map.put(:current_server_time, DateTime.utc_now())
    end
  end

  defmodule AuctionCommand do
    defstruct command: :get_current_state, data: nil

    def start_auction(%Auction{id: auction_id}) do
      %AuctionCommand{command: :start_auction, data: auction_id}
    end

    def end_auction(%Auction{id: auction_id}) do
      %AuctionCommand{command: :end_auction, data: auction_id}
    end

    def end_auction_decision_period(%Auction{id: auction_id}) do
      %AuctionCommand{command: :end_auction_decision_period, data: auction_id}
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

  def start_link(auction) do
    state = AuctionState.from_auction(auction)
    GenServer.start_link(__MODULE__, state, name: get_auction_store_name(auction.id))
  end

  def init(auction_state) do
    state = Map.put(auction_state, :status, calculate_status(auction_state))
    updated_state = AuctionState.maybe_update_times(state)
    {:ok, updated_state}
  end

   # Client
  def get_current_state(%Auction{id: auction_id}) do
    with {:ok, pid} <- find_pid(auction_id),
    do: GenServer.call(pid, :get_current_state)
  end

  def process_command(%AuctionCommand{command: :start_auction, data: data}, auction_id) do
    with {:ok, pid} <- find_pid(auction_id),
    do: GenServer.cast(pid, {:start_auction, data})
  end

  def process_command(%AuctionCommand{command: :end_auction, data: data}, auction_id) do
    with {:ok, pid} <- find_pid(auction_id),
    do: GenServer.cast(pid, {:end_auction, data})
  end

  def process_command(%AuctionCommand{command: :end_auction_decision_period, data: data}, auction_id) do
    with {:ok, pid} <- find_pid(auction_id),
      do: GenServer.cast(pid, {:end_auction_decision_period, data})
  end

  def process_command(%AuctionCommand{command: cmd, data: data}, auction_id) do
    with {:ok, pid} <- find_pid(auction_id),
    do: GenServer.call(pid, {cmd, data})
  end

   # Server
  def handle_call(:get_current_state, _from, current_state) do
    updated_state = AuctionState.maybe_update_times(current_state)
    {:reply, updated_state, updated_state}
  end

  def handle_cast({:start_auction, _}, current_state = %{auction_id: auction_id}) do
    # Get the current Auction State from current_state
    # process the start_auction command based on that state.
    TimersSupervisor.start_timer({auction_id, :duration})
    new_state = AuctionState.maybe_update_times(%AuctionState{current_state | status: :open})
    AuctionNotifier.notify_participants(new_state)

    # broadcast to the auction channel
    {:noreply, new_state}
  end

  def handle_cast({:end_auction, _}, current_state = %{auction_id: auction_id}) do
    TimersSupervisor.start_timer({auction_id, :decision_duration})
    :timer.sleep(200)
    new_state = AuctionState.maybe_update_times(%AuctionState{current_state | status: :decision})
    AuctionNotifier.notify_participants(new_state)

    {:noreply, new_state}
  end

  def handle_cast({:end_auction_decision_period, _}, current_state) do
    new_state = %AuctionState{current_state | status: :closed, time_remaining: 0}
    AuctionNotifier.notify_participants(new_state)

    {:noreply, new_state}
  end

  defp calculate_status(_auction) do
    :pending
    # Go through event log
  end
end
