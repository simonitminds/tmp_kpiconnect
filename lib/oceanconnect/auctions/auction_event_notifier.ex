defmodule Oceanconnect.Auctions.EventNotifier do
  import Oceanconnect.Auctions.Guards

  alias Oceanconnect.Auctions

  alias Oceanconnect.Auctions.{
    Auction,
    AuctionCache,
    AuctionScheduler,
    AuctionTimer,
    AuctionEvent,
    Command,
    Aggregate
  }

  def emit(state, event = %AuctionEvent{}) do
    # React before emitting the event to ensure things like cache updates and
    # persistence have occurred before other handlers respond.
    react_to(event, state)
    broadcast(event, state)
    {:ok, true}
  end

  def broadcast(event = %AuctionEvent{auction_id: auction_id}, state) do
    :ok = Phoenix.PubSub.broadcast(:auction_pubsub, "auction:#{auction_id}", {event, state})
    :ok = Phoenix.PubSub.broadcast(:auction_pubsub, "auctions", {event, state})
  end

  def react_to(%AuctionEvent{type: :auction_updated, data: auction}, _state) do
    update_cache(auction)

    auction
    |> Command.update_scheduled_start()
    |> AuctionScheduler.process_command(false)
  end

  def react_to(%AuctionEvent{type: :upcoming_auction_notified}, _state) do
    # noop
  end

  def react_to(
        %AuctionEvent{type: :auction_started, auction_id: auction_id, time_entered: started_at},
        _state
      ) do
    auction = Auctions.get_auction!(auction_id)
    auction = %{auction | auction_started: started_at}
    update_cache(auction)

    auction
    |> Command.start_duration_timer()
    |> AuctionTimer.process_command()

    auction
    |> Command.cancel_scheduled_start()
    |> AuctionScheduler.process_command(nil)
  end

  def react_to(
        %AuctionEvent{type: :auction_ended, auction_id: auction_id, time_entered: ended_at},
        _state
      ) do
    auction = Auctions.get_auction!(auction_id)
    auction = %{auction | auction_ended: ended_at}
    update_cache(auction)

    auction
    |> Command.start_decision_duration_timer()
    |> AuctionTimer.process_command()
  end

  def react_to(
        %AuctionEvent{type: :auction_closed, auction_id: auction_id, time_entered: closed_at},
        _state
      ) do
    auction = Auctions.get_auction!(auction_id)
    auction = %{auction | auction_closed_time: closed_at}
    update_cache(auction)

    AuctionTimer.cancel_timer(auction_id, :decision_duration)
  end

  def react_to(
        %AuctionEvent{type: :auction_expired, auction_id: auction_id, time_entered: expired_at},
        state
      ) do
    auction = Auctions.get_auction!(auction_id)
    auction = %{auction | auction_closed_time: expired_at}
    update_cache(auction)

    AuctionTimer.cancel_timer(auction_id, :decision_duration)
  end

  def react_to(
        %AuctionEvent{type: :auction_canceled, auction_id: auction_id, time_entered: canceled_at},
        _state
      ) do
    auction = Auctions.get_auction!(auction_id)
    auction = %{auction | auction_closed_time: canceled_at}
    update_cache(auction)

    AuctionTimer.cancel_timer(auction_id, :duration)
    AuctionTimer.cancel_timer(auction_id, :decision_duration)
  end

  def react_to(%AuctionEvent{type: :duration_extended, auction_id: auction_id}, _state) do
    auction_id
    |> Command.extend_duration()
    |> AuctionTimer.process_command()
  end

  def react_to(
        %AuctionEvent{
          type: :winning_solution_selected,
          auction_id: auction_id,
          data: %{port_agent: port_agent}
        },
        _state
      ) do
    auction = Auctions.get_auction!(auction_id)

    %{auction | port_agent: port_agent}
    |> update_cache()
  end

<<<<<<< HEAD
  def react_to(%AuctionEvent{type: :auction_finalized, auction_id: auction_id}, state) do
    with auction = %struct{} when is_auction(struct) <- Auctions.get_auction!(auction_id),
         {:ok, _snapshot_event} <- Aggregate.snapshot(state),
=======
  def react_to(%AuctionEvent{type: :auction_finalized, data: %{auction: auction}}, state) do
    with {:ok, _snapshot_event} <- Aggregate.snapshot(state),
>>>>>>> Emails are shredding and mix formatted. Shoulda broke that into a separate commit, but whatevs
         {:ok, finalized_auction} <- Auctions.finalize_auction(auction, state) do
      Auctions.AuctionsSupervisor.stop_child(finalized_auction)
    else
      {:error, _msg} ->
        require Logger
        Logger.error("Could not finalize auction detail records for auction #{auction_id}")
    end
  end

  def react_to(%AuctionEvent{}, _state) do
    # Nothing by default
  end

  defp update_cache(auction = %struct{}) when is_auction(struct) do
    auction
    |> Command.update_cache()
    |> AuctionCache.process_command()
  end
end
