defmodule Oceanconnect.Notifications.EventHandlers.ChannelNotifier do
  use GenServer

  import Oceanconnect.Auctions.Guards

  alias Oceanconnect.Auctions

  alias Oceanconnect.Auctions.{
    AuctionBid,
    AuctionEvent,
    AuctionNotifier
  }

  @registry_name :auction_event_handler_registry

  # Client
  def start_link(auction_id) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  # Server

  def init([]) do
    Phoenix.PubSub.subscribe(:auction_pubsub, "auctions")
    {:ok, []}
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
    |> Auctions.get_auction!()
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
    |> Auctions.get_auction!()
    |> AuctionNotifier.notify_participants()

    {:noreply, state}
  end

  def handle_info(
        %AuctionEvent{type: :auction_created, data: %struct{scheduled_start: nil}},
        state
      )
      when is_auction(struct) do
    {:noreply, state}
  end

  def handle_info(
        %AuctionEvent{type: :auction_created, data: auction = %struct{}},
        state
      )
      when is_auction(struct) do
    AuctionNotifier.notify_participants(auction)
    {:noreply, state}
  end

  def handle_info(
        %AuctionEvent{
          type: :auction_started,
          data: %{state: auction_state = %state_struct{}}
        },
        state
      )
      when is_auction_state(state_struct) do
    AuctionNotifier.notify_participants(auction_state)
    {:noreply, state}
  end

  def handle_info(
        %AuctionEvent{
          type: :auction_ended,
          data: %{state: auction_state = %state_struct{}}
        },
        state
      )
      when is_auction_state(state_struct) do
    AuctionNotifier.notify_participants(auction_state)
    {:noreply, state}
  end

  def handle_info(
        %AuctionEvent{
          type: type,
          data: %{state: auction_state = %state_struct{}}
        },
        state
      )
      when is_auction_state(state_struct) and
             type in [:auction_expired, :auction_canceled, :auction_closed] do
    AuctionNotifier.notify_participants(auction_state)
    {:noreply, state}
  end

  def handle_info(
        %AuctionEvent{type: :auction_finalized, data: %{auction: auction = %struct{}}},
        state
      )
      when is_auction(struct) do
    AuctionNotifier.notify_participants(auction)
    {:noreply, state}
  end

  def handle_info(%AuctionEvent{type: _, data: auction = %struct{scheduled_start: start}}, state)
      when is_auction(struct) and not is_nil(start) do
    AuctionNotifier.notify_participants(auction)
    {:noreply, state}
  end

  def handle_info(%AuctionEvent{type: _type, data: auction_state = %state_struct{}}, state)
      when is_auction_state(state_struct) do
    AuctionNotifier.notify_participants(auction_state)
    {:noreply, state}
  end

  def handle_info(
        %AuctionEvent{type: _type, data: %{state: auction_state = %state_struct{}}},
        state
      )
      when is_auction_state(state_struct) do
    AuctionNotifier.notify_participants(auction_state)
    {:noreply, state}
  end

  def handle_info(
        %AuctionEvent{
          type: :comment_submitted,
          data: %{state: auction_state = %state_struct{}}
        },
        state
      )
      when is_auction_state(state_struct) do
    AuctionNotifier.notify_participants(auction_state)
    {:noreply, state}
  end

  def handle_info(
        %AuctionEvent{
          type: :comment_unsubmitted,
          data: %{state: auction_state = %state_struct{}}
        },
        state
      )
      when is_auction_state(state_struct) do
    AuctionNotifier.notify_participants(auction_state)
    {:noreply, state}
  end

  def handle_info(
        %AuctionEvent{
          type: :barge_submitted,
          data: %{state: auction_state = %state_struct{}}
        },
        state
      )
      when is_auction_state(state_struct) do
    AuctionNotifier.notify_participants(auction_state)
    {:noreply, state}
  end

  def handle_info(
        %AuctionEvent{
          type: :barge_rejected,
          data: %{state: auction_state = %state_struct{}}
        },
        state
      )
      when is_auction_state(state_struct) do
    AuctionNotifier.notify_participants(auction_state)
    {:noreply, state}
  end

  def handle_info(
        %AuctionEvent{
          type: :barge_unsubmitted,
          data: %{state: auction_state = %state_struct{}}
        },
        state
      )
      when is_auction_state(state_struct) do
    AuctionNotifier.notify_participants(auction_state)
    {:noreply, state}
  end

  def handle_info(
        %AuctionEvent{type: :barge_approved, data: %{state: auction_state = %state_struct{}}},
        state
      )
      when is_auction_state(state_struct) do
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
