defmodule Oceanconnect.Auctions.AuctionTimerTest do
  use Oceanconnect.DataCase
  alias Oceanconnect.Auctions.{AuctionTimer, AuctionSupervisor, Command}

  setup do
    auction = insert(:auction, duration: 15 * 60_000, decision_duration: 10 * 60_000)
    {:ok, _pid} = start_supervised({AuctionSupervisor, {auction, %{exclude_children: [:auction_event_handler, :auction_scheduler]}}})
    {:ok, %{auction: auction}}
  end

  test "start auction_duration_timer for auction", %{auction: auction} do
    auction.id
    |> Command.start_duration_timer
    |> AuctionTimer.process_command

    time_remaining = AuctionTimer.read_timer(auction.id, :duration)
    assert round(Float.round(time_remaining / 10) * 10) == auction.duration

    :timer.sleep(500)
    assert AuctionTimer.read_timer(auction.id, :duration) < auction.duration
  end

  test "start auction_decision_duration_timer for auction", %{auction: auction} do
    auction.id
    |> Command.start_duration_timer
    |> AuctionTimer.process_command

    auction.id
    |> Command.start_decision_duration_timer
    |> AuctionTimer.process_command

    time_remaining = AuctionTimer.read_timer(auction.id, :decision_duration)
    assert round(Float.round(time_remaining / 10) * 10) == auction.decision_duration

    :timer.sleep(500)
    assert AuctionTimer.read_timer(auction.id, :decision_duration) < auction.decision_duration
  end

  test "cancel_timer/2 cancels the specified timer", %{auction: auction} do
    Oceanconnect.Auctions.start_auction(auction)
    :timer.sleep(500)
    refute AuctionTimer.timer_ref(auction.id, :duration) == false

    AuctionTimer.cancel_timer(auction.id, :duration)
    assert AuctionTimer.timer_ref(auction.id, :duration) == false
  end

  test "cancel_timer/2 gracefully continues if timer doesn't exist", %{auction: auction} do
    AuctionTimer.cancel_timer(auction.id, :duration)
    assert AuctionTimer.timer_ref(auction.id, :duration) == false
  end
end
