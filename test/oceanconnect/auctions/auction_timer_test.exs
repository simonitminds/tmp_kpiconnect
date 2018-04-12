defmodule Oceanconnect.Auctions.AuctionTimerTest do
  use Oceanconnect.DataCase
  alias Oceanconnect.Auctions.{AuctionTimer, AuctionSupervisor, Command}

  setup do
    auction = insert(:auction, duration: 15 * 60_000, decision_duration: 10 * 60_000)
    {:ok, _pid} = start_supervised({AuctionSupervisor, auction})
    {:ok, %{auction: auction}}
  end

  test "start auction_duration_timer for auction", %{auction: auction} do
    auction
    |> Command.start_duration_timer
    |> AuctionTimer.process_command

    ref = AuctionTimer.timer_ref(auction.id, :duration)
    assert round(Float.round(Process.read_timer(ref) / 10) * 10) == auction.duration

    :timer.sleep(500)
    assert Process.read_timer(ref) < auction.duration
  end

  test "start auction_decision_duration_timer for auction", %{auction: auction} do
    auction
    |> Command.start_decision_duration_timer
    |> AuctionTimer.process_command

    ref = AuctionTimer.timer_ref(auction.id, :decision_duration)
    assert round(Float.round(Process.read_timer(ref) / 10) * 10) == auction.decision_duration

    :timer.sleep(500)
    assert Process.read_timer(ref) < auction.decision_duration
  end
end
