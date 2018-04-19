defmodule Oceanconnect.Auctions.AuctionEventStore do
  alias Oceanconnect.Auctions.{Auction, AuctionEvent, AuctionEventStorage}

  use GenServer
  @registry_name :auction_event_store_registry
  @event_storage Application.get_env(:oceanconnect, :event_storage) || AuctionEventStorage

  # Client

  #TODO try and remove the fetching of events to init.
  def start_link(auction_id) do
    events = event_list(%Auction{id: auction_id})
    GenServer.start_link(__MODULE__, {auction_id, events}, name: get_event_store_name(auction_id))
  end

  def find_pid(auction_id) do
    with [{pid, _}] <- Registry.lookup(@registry_name, auction_id) do
      {:ok, pid}
    else
      [] -> {:error, "Auction Store Not Started"}
    end
  end

  defp get_event_store_name(auction_id) do
    {:via, Registry, {@registry_name, auction_id}}
  end

  def event_list(%Auction{id: id}) do
    case find_pid(id) do
      {:ok, pid} -> GenServer.call(pid, :get_event_list)
      {:error, "Auction Store Not Started"} ->
        @event_storage.events_by_auction(id)
    end
  end

  # Server
  def init({auction_id, nil}) do
    Phoenix.PubSub.subscribe(:auction_pubsub, "auction:#{auction_id}")
    {:ok, []}
  end

  def init({auction_id, events}) do
    Phoenix.PubSub.subscribe(:auction_pubsub, "auction:#{auction_id}")
    {:ok, events}
  end

  def handle_call(:get_event_list, _from, current_state) do
    {:reply, current_state, current_state}
  end

  def handle_info(event = %AuctionEvent{auction_id: auction_id}, current_events) do
    {:ok, %AuctionEventStorage{event: persisted_event}} = @event_storage.persist(%AuctionEventStorage{event: event, auction_id: auction_id})
    events = [persisted_event | current_events]
    {:noreply, events}
  end
end
