defmodule Oceanconnect.Auctions.AuctionStore do
#  defmodule AuctionState do
#    defstruct status: :pending
#  end
#
#  defmodule AuctionCommand do
#    defstruct command: :get_current_state, data: nil
#
#    def start_auction(%Oceanconnect.Auctions.Auction{id: auction_id}) do
#      %AuctionCommand{command: :start_auction, data: auction_id}
#    end
#  end
#
#  # Client
#
#  def get_current_state(%Oceanconnat.Auctions.Auction{id: auction_id}) do
#    {:ok, %AuctionState{}} = GenServer.call(__MODULE__, {:get_current_state, auction_id})
#  end
#
#  def process_command(%AuctionCommand{command: cmd, data: data}) do
#    {:ok, %AuctionState{}} = GenServer.call(__MODULE__, {cmd, data})
#  end
#
#  # Server
#  def handle_call({:get_current_state, auction_id}, _from, current_state) do
#    {:reply, current_state, current_state}
#  end
#
end
