defmodule Oceanconnect.Auctions.AuctionCache do
  use GenServer
  import Oceanconnect.Auctions.Guards
  alias Oceanconnect.Auctions.Command
  @registry_name :auction_cache_registry

  def start_link(auction = %struct{id: auction_id}) when is_auction(struct) do
    initial_state = %{
      auction: auction,
      available: false
    }

    GenServer.start_link(__MODULE__, initial_state, name: get_auction_cache_name(auction_id))
  end

  def init(cache_state) do
    {:ok, cache_state}
  end

  def process_command(%Command{command: :update_cache, data: auction = %struct{id: auction_id}})
      when is_auction(struct) do
    with {:ok, pid} <- find_pid(auction_id),
         do: GenServer.cast(pid, {:update_cache, auction})
  end

  def make_cache_available(auction_id) do
    with {:ok, pid} <- find_pid(auction_id),
         do: GenServer.call(pid, {:make_cache_available, auction_id})
  end

  def read(auction_id) do
    with {:ok, pid} <- find_pid(auction_id) do
      try do
        GenServer.call(pid, :read_cache)
      catch
        :exit, _ -> {:error, "Auction Cache Not Started"}
      end
    end
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

  def handle_cast({:update_cache, auction = %struct{}}, current_state) when is_auction(struct) do
    updated_state = Map.put(current_state, :auction, auction)

    {:noreply, updated_state}
  end

  def handle_call({:make_cache_available, auction_id}, _from, current_state) do
    new_state = Map.put(current_state, :available, true)

    {:reply, auction_id, new_state}
  end

  def handle_call(:read_cache, _from, current_state = %{available: false}),
    do: {:reply, {:error, "Auction Not Available"}, current_state}

  def handle_call(:read_cache, _from, current_state = %{auction: auction}) do
    {:reply, {:ok, auction}, current_state}
  end
end
