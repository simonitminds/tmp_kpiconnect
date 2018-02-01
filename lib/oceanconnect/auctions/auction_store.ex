defmodule Oceanconnect.Auctions.AuctionStore do
  use GenServer
  alias Oceanconnect.Auctions
  alias Oceanconnect.Auctions.AuctionStore.{AuctionCommand, AuctionState}

  @registry_name :auctions_registry

  def find_pid(auction_id) do
    with [{pid, _}] <- Registry.lookup(@registry_name, auction_id) do
      {:ok, pid}
    else
      [] -> {:error, "Not Started"}
    end
  end

  defmodule AuctionState do
    defstruct auction_id: nil, status: :pending
  end

  defmodule AuctionCommand do
    defstruct command: :get_current_state, data: nil

    def start_auction(%Oceanconnect.Auctions.Auction{id: auction_id}) do
      %AuctionCommand{command: :start_auction, data: auction_id}
    end

    def end_auction(%Oceanconnect.Auctions.Auction{id: auction_id}) do
      %AuctionCommand{command: :end_auction, data: auction_id}
    end
  end

  defp get_auction_store_name(auction_id) do
    {:via, Registry, {@registry_name, auction_id}}
  end

  def start_link(auction_id) when is_integer(auction_id) do
    GenServer.start_link(__MODULE__, auction_id, name: get_auction_store_name(auction_id))
  end

  def init(auction_id) do
    auction = Auctions.get_auction!(auction_id)
    state = %AuctionState{auction_id: auction.id, status: calculate_status(auction)}
    {:ok, state}
  end

   # Client
  def get_current_state(%Oceanconnect.Auctions.Auction{id: auction_id}) do
    with {:ok, pid} <- find_pid(auction_id),
    do: GenServer.call(pid, :get_current_state)
  end

  def process_command(%AuctionCommand{command: :start_auction, data: data}, auction_id) do
    with {:ok, pid} <- find_pid(auction_id),
    do: GenServer.cast(pid, {:start_auction, data})
  end

  def process_command(%AuctionCommand{command: cmd, data: data}, auction_id) do
    with {:ok, pid} <- find_pid(auction_id),
    do: GenServer.call(pid, {cmd, data})
  end

   # Server
  def handle_call(:get_current_state, _from, current_state) do
    # Get the Auction State from current_state
    {:reply, current_state, current_state}
  end

  def handle_cast({:start_auction, _}, current_state) do
    # Get the current Auction State from current_state
    # process the start_auction command based on that state.
    new_state = %AuctionState{current_state | status: :open}
    # broadcast to the auction channel
    {:noreply, new_state}
  end

  def handle_cast({:end_auction, _}, current_state) do
    new_state = %AuctionState{current_state | status: :closed}
    {:noreply, new_state}
  end

  defp calculate_status(_auction) do
    :pending
    # Go through event log
  end
end
