defmodule Oceanconnect.Auctions.AuctionEventHandler do
  use GenServer
  alias Oceanconnect.Auctions

  alias Oceanconnect.Auctions.{
    Auction,
    AuctionBid,
    AuctionEvent,
    AuctionNotifier,
    AuctionStore.AuctionState,
    AuctionEventStore
  }

  @registry_name :auction_event_handler_registry
  require Logger

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
          auction_id: auction_id,
          type: :bids_revoked,
          data: %{supplier_id: _supplier_id}
        },
        state
      ) do
    auction_id
    |> Auctions.AuctionCache.read()
    |> AuctionNotifier.notify_participants()

    {:noreply, state}
  end

  def handle_info(
        %AuctionEvent{type: :auction_created, data: %Auction{scheduled_start: nil}},
        state
      ) do
    {:noreply, state}
  end

  def handle_info(
        %AuctionEvent{type: :auction_created, data: auction = %Auction{}},
        state
      ) do
    AuctionNotifier.notify_participants(auction)
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
    AuctionNotifier.notify_participants(auction_state)
    {:noreply, state}
  end

  def handle_info(
        %AuctionEvent{
          type: type,
          data: %{state: auction_state = %AuctionState{}, auction: auction},
          time_entered: time_entered
        },
        state
      )
      when type in [:auction_expired, :auction_canceled, :auction_closed] do
    AuctionNotifier.notify_participants(auction_state)
    with {:ok, finalized_auction} <- Auctions.finalize_auction(auction, auction_state) do
      Auctions.AuctionsSupervisor.stop_child(auction)
    else
      {:error, _msg} ->
        Logger.error("Could not finalize auction detail records for auction #{auction.id}")
    end

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
