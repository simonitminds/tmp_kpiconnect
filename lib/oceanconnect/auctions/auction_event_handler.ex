defmodule Oceanconnect.Auctions.AuctionEventHandler do
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

  def handle_info({%AuctionEvent{type: type}, _aggregate_state}, state)
      when type == :auction_state_rebuilt do
    {:noreply, state}
  end

  def handle_info(
        {
          %AuctionEvent{
            auction_id: auction_id,
            type: _type,
            data: %{bid: bid = %AuctionBid{supplier_id: supplier_id}}
          },
          _aggregate_state
        },
        state
      ) do
    auction_id
    |> Auctions.get_auction!()
    |> AuctionNotifier.notify_updated_bid(bid, supplier_id)

    {:noreply, state}
  end

  def handle_info(
        {
          %AuctionEvent{
            auction_id: auction_id,
            type: :bids_revoked,
            data: %{supplier_id: _supplier_id}
          },
          aggregate_state
        },
        state
      ) do
    auction_id
    |> Auctions.get_auction!()
    |> AuctionNotifier.notify_participants(aggregate_state)

    {:noreply, state}
  end

  def handle_info(
        {%AuctionEvent{type: :auction_created, data: %struct{scheduled_start: nil}},
         _aggregate_state},
        state
      )
      when is_auction(struct) do
    {:noreply, state}
  end

  def handle_info(
        {%AuctionEvent{type: :auction_created, data: auction = %struct{}}, aggregate_state},
        state
      )
      when is_auction(struct) do
    AuctionNotifier.notify_participants(auction, aggregate_state)
    {:noreply, state}
  end

  def handle_info(
        {
          %AuctionEvent{
            type: :auction_started,
            data: %{state: auction_state = %state_struct{}}
          },
          aggregate_state
        },
        state
      )
      when is_auction_state(state_struct) do
    AuctionNotifier.notify_participants(aggregate_state)
    {:noreply, state}
  end

  def handle_info(
        {
          %AuctionEvent{
            type: :auction_ended,
            data: %{state: auction_state = %state_struct{}}
          },
          aggregate_state
        },
        state
      )
      when is_auction_state(state_struct) do
    AuctionNotifier.notify_participants(aggregate_state)
    {:noreply, state}
  end

  def handle_info(
        {
          %AuctionEvent{
            type: type,
            data: %{state: auction_state = %state_struct{}}
          },
          aggregate_state
        },
        state
      )
      when is_auction_state(state_struct) and
             type in [:auction_expired, :auction_canceled, :auction_closed] do
    AuctionNotifier.notify_participants(aggregate_state)
    {:noreply, state}
  end

  def handle_info(
        {%AuctionEvent{type: :auction_finalized, data: %{auction: auction = %struct{}}},
         aggregate_state},
        state
      )
      when is_auction(struct) do
    AuctionNotifier.notify_participants(auction, aggregate_state)
    {:noreply, state}
  end

  def handle_info(
        {%AuctionEvent{type: _, data: auction = %struct{scheduled_start: start}},
         aggregate_state},
        state
      )
      when is_auction(struct) and not is_nil(start) do
    AuctionNotifier.notify_participants(auction, aggregate_state)
    {:noreply, state}
  end

  def handle_info(
        {%AuctionEvent{type: _type, data: auction_state = %state_struct{}}, aggregate_state},
        state
      )
      when is_auction_state(state_struct) do
    AuctionNotifier.notify_participants(aggregate_state)
    {:noreply, state}
  end

  def handle_info(
        {%AuctionEvent{type: _type, data: %{state: auction_state = %state_struct{}}},
         aggregate_state},
        state
      )
      when is_auction_state(state_struct) do
    AuctionNotifier.notify_participants(aggregate_state)
    {:noreply, state}
  end

  def handle_info(
        {
          %AuctionEvent{
            type: :comment_submitted,
            data: %{state: auction_state = %state_struct{}}
          },
          aggregate_state
        },
        state
      )
      when is_auction_state(state_struct) do
    AuctionNotifier.notify_participants(aggregate_state)
    {:noreply, state}
  end

  def handle_info(
        {
          %AuctionEvent{
            type: :comment_unsubmitted,
            data: %{state: auction_state = %state_struct{}}
          },
          aggregate_state
        },
        state
      )
      when is_auction_state(state_struct) do
    AuctionNotifier.notify_participants(aggregate_state)
    {:noreply, state}
  end

  def handle_info(
        {
          %AuctionEvent{
            type: :barge_submitted,
            data: %{state: auction_state = %state_struct{}}
          },
          aggregate_state
        },
        state
      )
      when is_auction_state(state_struct) do
    AuctionNotifier.notify_participants(aggregate_state)
    {:noreply, state}
  end

  def handle_info(
        {
          %AuctionEvent{
            type: :barge_unsubmitted,
            data: %{state: auction_state = %state_struct{}}
          },
          aggregate_state
        },
        state
      )
      when is_auction_state(state_struct) do
    AuctionNotifier.notify_participants(aggregate_state)
    {:noreply, state}
  end

  def handle_info(
        {
          %AuctionEvent{type: :barge_approved, data: %{state: auction_state = %state_struct{}}},
          aggregate_state
        },
        state
      )
      when is_auction_state(state_struct) do
    AuctionNotifier.notify_participants(aggregate_state)
    {:noreply, state}
  end

  def handle_info({_event, _aggregate_state}, state) do
    {:noreply, state}
  end

  def handle_info(_msg, state) do
    {:noreply, state}
  end


  # Private

  defp get_event_handler_name(auction_id) do
    {:via, Registry, {@registry_name, auction_id}}
  end
end
