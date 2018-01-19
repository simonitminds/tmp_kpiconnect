defmodule Oceanconnect.Auctions.AuctionStore do
  use GenServer
  alias Oceanconnect.Auctions
  alias Oceanconnect.Auctions.AuctionStore.{AuctionCommand, AuctionState}

  defmodule AuctionState do
    defstruct auction_id: nil, status: :pending
  end

  defmodule AuctionCommand do
    defstruct command: :get_current_state, data: nil

    def start_auction(%Oceanconnect.Auctions.Auction{id: auction_id}) do
      %AuctionCommand{command: :start_auction, data: auction_id}
    end
  end

  def start_link(auction_id) when is_integer(auction_id) do
    GenServer.start_link(__MODULE__, auction_id, name: __MODULE__)
  end

  def init(auction_id) do
    # loop over all the auctions and initialize state based off event store
     # state = %{}
     # state = for %Oceanconnect.Auction{id: auction_id} in Auctions.list_auctions
     auction = Auctions.get_auction!(auction_id)
     state = %AuctionState{auction_id: auction.id, status: calculate_status(auction)}
     # AuctionEvents.build_current_state(auction_id)
    {:ok, state}
  end

   # Client
  def get_current_state(%Oceanconnect.Auctions.Auction{id: auction_id}) do
    GenServer.call(__MODULE__, :get_current_state)
  end

  def process_command(%AuctionCommand{command: :start_auction, data: data}) do
    GenServer.cast(__MODULE__, {:start_auction, data})
  end

  def process_command(%AuctionCommand{command: cmd, data: data}) do
    GenServer.call(__MODULE__, {cmd, data})
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

  defp calculate_status(auction) do
    :pending
    # Go through event log
  end
end
