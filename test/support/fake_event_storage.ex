defmodule Oceanconnect.FakeEventStorage do
  alias Oceanconnect.FakeEventStorage.FakeEventStorageCache

  defmodule FakeEventStorageCache do
    use GenServer

    def start_link() do
      GenServer.start_link(__MODULE__, [], name: __MODULE__)
    end

    def init([]) do
      {:ok, %{events: [], next_id: 1}}
    end

    def seed(data) do
      GenServer.cast(__MODULE__, {:update_cache, data})
    end

    def add_event(event) do
      GenServer.cast(__MODULE__, {:add_event, event})
    end

    def read() do
      GenServer.call(__MODULE__, :read_cache)
    end

    def handle_cast({:update_cache, data}, _current_state) do
      {:noreply, data}
    end

    def handle_cast({:add_event, event}, %{events: events, next_id: next_id}) do
      event = %{event | id: next_id}

      {:noreply, %{
        events: [event | events],
        next_id: next_id + 1
      }}
    end

    def handle_call(:read_cache, _from, state), do: {:reply, state, state}
  end

  def events_by_auction(_id) do
    case Process.whereis(FakeEventStorageCache) do
      nil -> []
      _ -> FakeEventStorageCache.read()
    end
  end

  def persist(storage = %Oceanconnect.Auctions.AuctionEventStorage{event: event}) do
    FakeEventStorageCache.add_event(event)
    {:ok, storage}
  end
end
