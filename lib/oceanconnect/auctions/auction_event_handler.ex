defmodule Oceanconnect.Auctions.AuctionEventHandler do
  use GenServer
  alias Oceanconnect.Auctions

  alias Oceanconnect.Auctions.{
    Auction,
    AuctionBid,
    AuctionEvent,
    AuctionNotifier,
    AuctionStore.AuctionState
  }

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

  def handle_info(%AuctionEvent{type: type}, state) when type == :auction_state_rebuilt do
    {:noreply, state}
  end

  def handle_info(
        %AuctionEvent{
          auction_id: auction_id,
          type: _type,
          data: %{bid: bid = %AuctionBid{supplier_id: supplier_id}}
        },
        state
      ) do
    auction_id
    |> Auctions.AuctionCache.read()
    |> AuctionNotifier.notify_updated_bid(bid, supplier_id)

    {:noreply, state}
  end

  def handle_info(
        %AuctionEvent{
          type: :auction_started,
          data: %{state: auction_state = %AuctionState{}, auction: auction},
          time_entered: time_entered
        },
        state
      ) do
    auction
    |> Auctions.update_auction_without_event_storage!(%{scheduled_start: time_entered})

    AuctionNotifier.notify_participants(auction_state)
    {:noreply, state}
  end

  def handle_info(
        %AuctionEvent{
          type: :auction_ended,
          data: %{state: auction_state = %AuctionState{}, auction: auction},
          time_entered: time_entered
        },
        state
      ) do
    auction
    |> Auctions.update_auction_without_event_storage!(%{auction_ended: time_entered})

    AuctionNotifier.notify_participants(auction_state)
    {:noreply, state}
  end

  def handle_info(%AuctionEvent{type: _, data: auction = %Auction{scheduled_start: start}}, state)
      when not is_nil(start) do
    AuctionNotifier.notify_participants(auction)
    {:noreply, state}
  end

  def handle_info(%AuctionEvent{type: _type, data: auction_state = %AuctionState{}}, state) do
    AuctionNotifier.notify_participants(auction_state)
    {:noreply, state}
  end

  def handle_info(
        %AuctionEvent{type: _type, data: %{state: auction_state = %AuctionState{}}},
        state
      ) do
    AuctionNotifier.notify_participants(auction_state)
    {:noreply, state}
  end

  def handle_info(
        %AuctionEvent{type: :barge_submitted, data: %{state: auction_state = %AuctionState{}}},
        state
      ) do
    AuctionNotifier.notify_participants(auction_state)
    {:noreply, state}
  end

  def handle_info(
        %AuctionEvent{type: :barge_unsubmitted, data: %{state: auction_state = %AuctionState{}}},
        state
      ) do
    AuctionNotifier.notify_participants(auction_state)
    {:noreply, state}
  end

  def handle_info(
        %AuctionEvent{type: :barge_approved, data: %{state: auction_state = %AuctionState{}}},
        state
      ) do
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
