defmodule Oceanconnect.Auctions.AuctionStoreStarter do
  use GenServer
  alias Oceanconnect.Auctions
  alias Oceanconnect.Auctions.AuctionsSupervisor

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init([]) do
    Process.send_after(self(), :start_auction_stores, 1000)
    {:ok, []}
  end

  require Logger

  def handle_info(:start_auction_stores, _) do
    results =
      false
      |> Auctions.list_auctions()
      |> Enum.map(fn auction ->
        with {:ok, core_services_pid} <-
               AuctionsSupervisor.start_child(auction) do
          {auction.id, core_services_pid}
        else
          {:error, {:already_started, pid}} ->
            {auction.id, pid}

          error ->
            Logger.error(inspect(error))
            raise("Could Not Start AuctionStore for auction #{auction.id}")
        end
      end)

    {:noreply, results}
  end
end
