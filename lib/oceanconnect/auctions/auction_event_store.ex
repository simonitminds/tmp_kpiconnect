defmodule Oceanconnect.Auctions.AuctionEventStore do
  alias Oceanconnect.Auctions.{AuctionEvent, AuctionEventStorage}

  @event_storage Application.get_env(:oceanconnect, :event_storage) || AuctionEventStorage

  def persist(event = %AuctionEvent{auction_id: auction_id}) do
    %AuctionEventStorage{event: event, auction_id: auction_id}
    |> @event_storage.persist()
  end

  def event_list(auction_id) do
    @event_storage.events_by_auction(auction_id)
  end

  def participants_from_events(auction_id) do
    event_list(auction_id)
    |> Enum.map(& &1.user)
    |> Enum.reject(&is_nil(&1))
  end

  def create_auction_snapshot(
        event = %AuctionEvent{type: :auction_state_snapshotted, auction_id: auction_id}
      ) do
    {:ok, %AuctionEventStorage{event: _persisted_event}} =
      @event_storage.persist(%AuctionEventStorage{event: event, auction_id: auction_id})
  end
end
