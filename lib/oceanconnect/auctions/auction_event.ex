defmodule Oceanconnect.Auctions.AuctionEvent do
  use Ecto.Schema

  alias Oceanconnect.Auctions.{Auction, AuctionBarge, AuctionBid, AuctionEvent, Solution}
  alias Oceanconnect.Auctions.AuctionStore.{AuctionState, ProductBidState}

  defstruct id: nil,
            type: nil,
            data: nil,
            auction_id: nil,
            time_entered: nil,
            user: nil,
            version: 2

  alias __MODULE__

  def emit(%AuctionEvent{}, false), do: nil

  def emit(event = %AuctionEvent{type: _type, auction_id: id, data: _data, user: _user}, _emit) do
    :ok =
      Phoenix.PubSub.broadcast(
        :auction_pubsub,
        "auction:#{id}",
        Map.put(event, :id, UUID.uuid4(:hex))
      )

    {:ok, event}
  end

  def emit(event = %AuctionEvent{type: _type, auction_id: id, data: _data}, _emit) do
    updated_event =
      event
      |> Map.put(:id, UUID.uuid4(:hex))
      |> Map.put(:user, nil)

    :ok = Phoenix.PubSub.broadcast(:auction_pubsub, "auction:#{id}", updated_event)
    {:ok, updated_event}
  end

  def auction_state_snapshotted(auction = %Auction{id: auction_id}, new_state = %AuctionState{}) do
    %AuctionEvent{
      type: :auction_state_snapshotted,
      auction_id: auction_id,
      data: %{state: new_state, auction: auction},
      time_entered: DateTime.utc_now(),
    }
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
        auction = %Auction{id: auction_id, auction_started: auction_started},
        new_state = %AuctionState{},
        user
      ) do
    %AuctionEvent{
      type: :auction_started,
      auction_id: auction_id,
      data: %{state: new_state, auction: auction},
      time_entered: auction_started,
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

  def auction_rescheduled(auction = %Auction{id: auction_id}, user) do
    %AuctionEvent{
      type: :auction_rescheduled,
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

  def auction_expired(auction = %Auction{id: auction_id}, new_state = %AuctionState{}) do
    %AuctionEvent{
      type: :auction_expired,
      auction_id: auction_id,
      data: %{state: new_state, auction: auction},
      time_entered: DateTime.utc_now()
    }
  end

  def auction_canceled(auction = %Auction{id: auction_id}, new_state = %AuctionState{}, user) do
    %AuctionEvent{
      type: :auction_canceled,
      auction_id: auction_id,
      data: %{state: new_state, auction: auction},
      time_entered: DateTime.utc_now(),
      user: user
    }
  end

  def auction_closed(auction = %Auction{id: auction_id}, new_state = %AuctionState{}) do
    %AuctionEvent{
      type: :auction_closed,
      auction_id: auction_id,
      data: %{state: new_state, auction: auction},
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
        new_state = %ProductBidState{},
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
        new_state = %ProductBidState{},
        nil
      ) do
    %AuctionEvent{
      type: :auto_bid_placed,
      auction_id: auction_id,
      data: %{bid: bid, state: new_state},
      time_entered: time_entered,
      user: nil
    }
  end

  def auto_bid_placed(
        bid = %AuctionBid{auction_id: auction_id, time_entered: time_entered},
        new_state = %ProductBidState{},
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

  def auto_bid_triggered(
        bid = %AuctionBid{auction_id: auction_id, time_entered: time_entered},
        new_state = %ProductBidState{},
        user \\ nil
      ) do
    %AuctionEvent{
      type: :auto_bid_triggered,
      auction_id: auction_id,
      data: %{bid: bid, state: new_state},
      time_entered: time_entered,
      user: user
    }
  end

  def bids_revoked(
        auction_id,
        product,
        supplier_id,
        new_state,
        user \\ nil
      ) do
    %AuctionEvent{
      type: :bids_revoked,
      auction_id: auction_id,
      data: %{product: product, supplier_id: supplier_id, state: new_state},
      time_entered: DateTime.utc_now(),
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

  def winning_solution_selected(
        solution = %Solution{auction_id: auction_id},
        port_agent,
        state = %AuctionState{},
        user
      ) do
    %AuctionEvent{
      type: :winning_solution_selected,
      auction_id: auction_id,
      data: %{solution: solution, port_agent: port_agent, state: state},
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
