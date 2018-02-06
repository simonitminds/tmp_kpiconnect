defmodule Oceanconnect.Auctions.AuctionStore do
  use GenServer
  alias Oceanconnect.Auctions
  alias Oceanconnect.Auctions.{Auction, AuctionNotifier, AuctionTimer, TimersSupervisor}
  alias Oceanconnect.Auctions.AuctionStore.{AuctionCommand, AuctionState}

  @registry_name :auctions_registry

  defmodule AuctionState do
    defstruct auction_id: nil, status: :pending, current_server_time: nil, time_remaining: nil end

  defmodule AuctionCommand do
    defstruct command: :get_current_state, data: nil

    def start_auction(%Auction{id: auction_id}) do
      %AuctionCommand{command: :start_auction, data: auction_id}
    end

    def end_auction(%Auction{id: auction_id}) do
      %AuctionCommand{command: :end_auction, data: auction_id}
    end
  end

  def find_pid(auction_id) do
    with [{pid, _}] <- Registry.lookup(@registry_name, auction_id) do
      {:ok, pid}
    else
      [] -> {:error, "Auction Store Not Started"}
    end
  end

  def add_times_to_state?(state = %{status: :open}, auction_id) do
    time_remaining = Process.read_timer(AuctionTimer.timer_ref(auction_id))
    state
    |> Map.put(:time_remaining, time_remaining)
    |> Map.put(:current_server_time, DateTime.utc_now())
  end
  def add_times_to_state?(state, _auction_id), do: state

  defp get_auction_store_name(auction_id) do
    {:via, Registry, {@registry_name, auction_id}}
  end

  def start_link(auction_id) when is_integer(auction_id) do
    GenServer.start_link(__MODULE__, auction_id, name: get_auction_store_name(auction_id))
  end

  def init(auction_id) do
    auction = Auctions.get_auction!(auction_id)
    state = %AuctionState{auction_id: auction.id, status: calculate_status(auction)}
    updated_state = add_times_to_state?(state, auction_id)
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

  def process_command(%AuctionCommand{command: cmd, data: data}, auction_id) do
    with {:ok, pid} <- find_pid(auction_id),
    do: GenServer.call(pid, {cmd, data})
  end

   # Server
  def handle_call(:get_current_state, _from, current_state = %{auction_id: auction_id}) do
    # Get the Auction State from current_state
    updated_state = add_times_to_state?(current_state, auction_id)

    {:reply, updated_state, updated_state}
  end

  def handle_cast({:start_auction, _}, current_state = %{auction_id: auction_id}) do
    # Get the current Auction State from current_state
    # process the start_auction command based on that state.
    TimersSupervisor.start_timer(auction_id)
    new_state = add_times_to_state?(%AuctionState{current_state | status: :open}, auction_id)

    # broadcast to the auction channel
    {:noreply, new_state}
  end

  def handle_cast({:end_auction, _}, current_state = %{auction_id: auction_id}) do
    new_state = %AuctionState{current_state | status: :decision, time_remaining: 0}

    reduced_state = Map.take(new_state, [:status, :current_server_time, :time_remaining])
    AuctionNotifier.notify_participants(auction_id, %{id: auction_id, state: reduced_state})

    {:noreply, new_state}
  end

  defp calculate_status(_auction) do
    :pending
    # Go through event log
  end
end
