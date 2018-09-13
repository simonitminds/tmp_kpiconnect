defmodule Oceanconnect.Auctions.AuctionEvent do
  use Ecto.Schema

  alias Oceanconnect.Auctions.{Auction, AuctionBarge, AuctionBid, AuctionEvent}
  alias Oceanconnect.Auctions.AuctionStore.AuctionState

  defstruct id: nil,
            type: nil,
            data: nil,
            auction_id: nil,
            time_entered: nil,
            user: nil

  alias __MODULE__

  def emit(%AuctionEvent{}, false), do: nil

  def emit(event = %AuctionEvent{type: _type, auction_id: id, data: _data, user: _user}, _emit) do
    Phoenix.PubSub.broadcast(
      :auction_pubsub,
      "auction:#{id}",
      Map.put(event, :id, UUID.uuid4(:hex))
    )
  end

  def emit(event = %AuctionEvent{type: _type, auction_id: id, data: _data}, _emit) do
    updated_event =
      event
      |> Map.put(:id, UUID.uuid4(:hex))
      |> Map.put(:user, nil)

    Phoenix.PubSub.broadcast(:auction_pubsub, "auction:#{id}", updated_event)
  end

  def auction_created(auction = %Auction{id: auction_id}, user) do
    %AuctionEvent{
      type: :auction_created,
      auction_id: auction_id,
      data: auction,
      time_entered: DateTime.utc_now(),
      user: user
    }
  end

  def upcoming_auction_notified(auction = %Auction{id: auction_id}) do
    %AuctionEvent{
      type: :upcoming_auction_notified,
      auction_id: auction_id,
      data: auction,
      time_entered: DateTime.utc_now()
    }
  end

  def auction_started(
        auction = %Auction{id: auction_id, scheduled_start: scheduled_start},
        new_state = %AuctionState{},
        user
      ) do
    %AuctionEvent{
      type: :auction_started,
      auction_id: auction_id,
      data: %{state: new_state, auction: auction},
      time_entered: scheduled_start,
      user: user
    }
  end

  def auction_updated(auction = %Auction{id: auction_id}, user) do
    %AuctionEvent{
      type: :auction_updated,
      auction_id: auction_id,
      data: auction,
      time_entered: DateTime.utc_now(),
      user: user
    }
  end

  def auction_ended(
        auction = %Auction{id: auction_id, auction_ended: ended_at},
        new_state = %AuctionState{}
      ) do
    %AuctionEvent{
      type: :auction_ended,
      auction_id: auction_id,
      data: %{state: new_state, auction: auction},
      time_entered: ended_at
    }
  end

  def auction_expired(auction_id, new_state = %AuctionState{}) do
    %AuctionEvent{
      type: :auction_expired,
      auction_id: auction_id,
      data: new_state,
      time_entered: DateTime.utc_now()
    }
  end

  def auction_canceled(%Auction{id: auction_id}, new_state = %AuctionState{}, user) do
    %AuctionEvent{
      type: :auction_canceled,
      auction_id: auction_id,
      data: new_state,
      time_entered: DateTime.utc_now(),
      user: user
    }
  end

  def auction_closed(auction_id, new_state = %AuctionState{}) do
    %AuctionEvent{
      type: :auction_closed,
      auction_id: auction_id,
      data: new_state,
      time_entered: DateTime.utc_now()
    }
  end

  def auction_state_rebuilt(auction_id, state = %AuctionState{}, time_remaining) do
    %AuctionEvent{
      type: :auction_state_rebuilt,
      data: %{state: state, time_remaining: time_remaining},
      time_entered: DateTime.utc_now(),
      auction_id: auction_id
    }
  end

  def bid_placed(
        bid = %AuctionBid{auction_id: auction_id, time_entered: time_entered},
        new_state = %AuctionState{},
        user
      ) do
    %AuctionEvent{
      type: :bid_placed,
      auction_id: auction_id,
      data: %{bid: bid, state: new_state},
      time_entered: time_entered,
      user: user
    }
  end

  def auto_bid_placed(
    bid = %AuctionBid{auction_id: auction_id, time_entered: time_entered},
    new_state = %AuctionState{},
    nil
  ) do
    %AuctionEvent{
      type: :auto_bid_placed,
      auction_id: auction_id,
      data: %{bid: bid, state: new_state},
      time_entered: DateTime.utc_now(),
      user: nil
    }
  end

  def auto_bid_placed(
        bid = %AuctionBid{auction_id: auction_id, time_entered: time_entered},
        new_state = %AuctionState{},
        user
      ) do
    %AuctionEvent{
      type: :auto_bid_placed,
      auction_id: auction_id,
      data: %{bid: bid, state: new_state},
      time_entered: time_entered,
      user: user
    }
  end

  def duration_extended(auction_id, extension_time) do
    %AuctionEvent{
      type: :duration_extended,
      auction_id: auction_id,
      data: %{extension_time: extension_time},
      time_entered: DateTime.utc_now()
    }
  end

  def winning_bid_selected(
        bid = %AuctionBid{auction_id: auction_id},
        state = %AuctionState{},
        user
      ) do
    %AuctionEvent{
      type: :winning_bid_selected,
      auction_id: auction_id,
      data: %{bid: bid, state: state},
      time_entered: DateTime.utc_now(),
      user: user
    }
  end

  def barge_submitted(
        auction_barge = %AuctionBarge{auction_id: auction_id},
        state = %AuctionState{},
        user
      ) do
    %AuctionEvent{
      type: :barge_submitted,
      auction_id: auction_id,
      data: %{auction_barge: auction_barge, state: state},
      time_entered: DateTime.utc_now(),
      user: user
    }
  end

  def barge_unsubmitted(
        auction_barge = %AuctionBarge{auction_id: auction_id},
        state = %AuctionState{},
        user
      ) do
    %AuctionEvent{
      type: :barge_unsubmitted,
      auction_id: auction_id,
      data: %{auction_barge: auction_barge, state: state},
      time_entered: DateTime.utc_now(),
      user: user
    }
  end

  def barge_approved(
        auction_barge = %AuctionBarge{auction_id: auction_id},
        state = %AuctionState{},
        user
      ) do
    %AuctionEvent{
      type: :barge_approved,
      auction_id: auction_id,
      data: %{auction_barge: auction_barge, state: state},
      time_entered: DateTime.utc_now(),
      user: user
    }
  end

  def barge_rejected(
        auction_barge = %AuctionBarge{auction_id: auction_id},
        state = %AuctionState{},
        user
      ) do
    %AuctionEvent{
      type: :barge_rejected,
      auction_id: auction_id,
      data: %{auction_barge: auction_barge, state: state},
      time_entered: DateTime.utc_now(),
      user: user
    }
  end
end
