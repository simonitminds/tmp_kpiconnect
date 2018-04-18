defmodule Oceanconnect.Auctions.AuctionCache do
  use GenServer
  @registry_name :auction_cache_registry
  #alias __MODULE__
  alias Oceanconnect.Auctions.{Auction}
  # AuctionStore.AuctionState}

  def start_link(auction = %Auction{id: id}) do
    inital_state = %{
     auction: auction
     #, auction_state: %AuctionState{}
    }
    GenServer.start_link(__MODULE__, inital_state , name: get_auction_cache_name(id))
  end

  def init(cache_state) do
    {:ok, cache_state}
  end

  def update_cache(auction = %Auction{id: auction_id}) do
    with {:ok, pid} <- find_pid(auction_id),
         do:        GenServer.cast(pid, {:update_cache, auction})
  end

  def read(auction_id) do
    with {:ok, pid} <- find_pid(auction_id),
      do:        GenServer.call(pid, :read_cache)
  end

  def find_pid(auction_id) do
    with [{pid, _}] <- Registry.lookup(@registry_name, auction_id) do
      {:ok, pid}
    else
      [] -> {:error, "Auction Cache Not Started"}
    end
  end

  defp get_auction_cache_name(auction_id) do
    {:via, Registry, {@registry_name, auction_id}}
  end

  def handle_cast({:update_cache, auction = %Auction{}}, _current_state) do
    updated_state = %{auction: auction}
    {:noreply, updated_state}
  end

  def handle_call(:read_cache, _from, current_state = %{auction: auction}), do: {:reply, auction, current_state}
end

