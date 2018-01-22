defmodule Oceanconnect.Auctions.AuctionStoreStarter do
  use GenServer
  alias Oceanconnect.Auctions
  alias Oceanconnect.Auctions.AuctionsSupervisor

  def start_link do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init([]) do
    Process.send_after(self(), :start_auction_stores, 1000)
    {:ok, []}
  end

  def handle_info(:start_auction_stores, _) do
    results = Auctions.list_auctions()
    |> Enum.map(fn(auction) ->
      with {:ok, pid} <- AuctionsSupervisor.start_child(auction.id)
        do
          {auction.id, pid}
        else
          {:error,  {:already_started, pid}} -> {auction.id, pid}
          _ -> raise("Could Not Start AuctionStore for auction #{auction.id}")
      end
    end)
    {:noreply, results}
  end
end
