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

  def non_barge_events(auction_id) do
    event_list(auction_id)
    |> Enum.reject(fn event ->
      event.type in [
        :barge_submitted,
        :barge_unsubmitted,
        :barge_approved,
        :barge_rejected
      ]
    end)
  end

  def barge_events(auction_id) do
    event_list(auction_id)
    |> Enum.filter(fn event ->
      event.type in [
        :barge_submitted,
        :barge_unsubmitted,
        :barge_approved,
        :barge_rejected
      ]
    end)
    |> Enum.reverse()
  end

  def bid_events(auction_id) do
    event_list(auction_id)
    |> Enum.filter(fn event ->
      event.type in [
        :bid_placed,
        :auto_bid_placed,
        :auto_bid_triggered,
        :bids_revoked,
        :winning_solution_selected
      ]
    end)
    |> Enum.reverse()
  end

  def timing_log_events(auction_id) do
    event_list(auction_id)
    |> Enum.filter(fn event ->
      event.type in [
        :auction_started,
        :auction_rescheduled,
        :auction_ended,
        :auction_expired,
        :auction_canceled,
        :auction_closed,
        :duration_extended,
        :winning_solution_selected,
        :bid_placed,
        :auto_bid_placed,
        :auto_bid_triggered,
        :bids_revoked
      ]
    end)
    |> Enum.reverse()
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
