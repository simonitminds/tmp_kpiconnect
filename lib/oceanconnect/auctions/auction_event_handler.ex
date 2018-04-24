defmodule Oceanconnect.Auctions.AuctionEventHandler do
  use GenServer
  alias Oceanconnect.Auctions
  alias Oceanconnect.Auctions.{AuctionBidList.AuctionBid, AuctionEvent, AuctionNotifier, AuctionStore.AuctionState}

  @registry_name :auction_event_handler_registry

  # Client
  def start_link(auction_id) do
    GenServer.start_link(__MODULE__, auction_id, name: get_event_handler_name(auction_id))
  end

  def find_pid(auction_id) do
    with [{pid, _}] <- Registry.lookup(@registry_name, auction_id) do
      {:ok, pid}
    else
      [] -> {:error, "Auction Store Not Started"}
    end
  end

  # Server

  def init(auction_id) do
    Phoenix.PubSub.subscribe(:auction_pubsub, "auction:#{auction_id}")
    {:ok, auction_id}
  end

  # TODO narrow the scope of which events we respond to with better pattern matching.
  def handle_info(%AuctionEvent{auction_id: auction_id, type: _type, data: %{bid: bid = %AuctionBid{supplier_id: supplier_id}}}, state) do
    auction_id
    |> Auctions.AuctionCache.read
    |> AuctionNotifier.notify_updated_bid(bid, supplier_id)
    {:noreply, state}
  end
  def handle_info(%AuctionEvent{type: _type, data: auction_state = %AuctionState{}}, state) do
    AuctionNotifier.notify_participants(auction_state)
    {:noreply, state}
  end

  def handle_info(_event, state) do
    {:noreply, state}
  end

  # Private

  defp get_event_handler_name(auction_id) do
    {:via, Registry, {@registry_name, auction_id}}
  end
end
