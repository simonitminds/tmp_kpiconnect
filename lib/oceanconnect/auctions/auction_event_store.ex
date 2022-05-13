defmodule Oceanconnect.Auctions.AuctionEventStore do
  alias Oceanconnect.Auctions.{AuctionEvent, AuctionEventStorage}

  @event_storage Application.compile_env(:oceanconnect, :event_storage) || AuctionEventStorage

  @fixture_events [
    :fixture_created,
    :fixture_updated,
    :fixture_changes_proposed,
    :fixture_delivered
  ]

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

  def fixture_events(auction_id, fixture_id) do
    event_list(auction_id)
    |> Enum.filter(&(&1.type in @fixture_events))
    |> Enum.filter(fn event ->
      cond do
        event.type in List.delete(@fixture_events, :fixture_updated) ->
          event.data.fixture.id == fixture_id

        true ->
          event.data.original.id == fixture_id
      end
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

  def delivery_events(auction_id) do
    event_list(auction_id)
    |> Enum.filter(fn event ->
      event.type in [
        :fixture_created,
        :fixture_updated,
        :claim_created,
        :claim_response_created
      ]
    end)
  end

  def participants_from_events(auction_id) do
    event_list(auction_id)
    |> Enum.map(& &1.user)
    |> Enum.reject(&is_nil(&1))
  end
end
