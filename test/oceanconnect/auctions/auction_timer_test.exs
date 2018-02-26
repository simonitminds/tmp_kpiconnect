defmodule Oceanconnect.Auctions.AuctionTimerTest do
  use Oceanconnect.DataCase
  alias Oceanconnect.Auctions.AuctionTimer

  setup do
    auction = insert(:auction, duration: 15 * 60_000, decision_duration: 10 * 60_000)
    {:ok, %{auction: auction}}
  end

  test "start auction_duration_timer for auction", %{auction: auction} do
    assert {:ok, _pid} = AuctionTimer.start_link({auction.id, auction.duration, :duration})
    ref = AuctionTimer.timer_ref(auction.id, :duration)
    assert round(Float.round(Process.read_timer(ref) / 10) * 10) == auction.duration

    :timer.sleep(500)
    assert Process.read_timer(ref) < auction.duration
  end

  test "start auction_decision_duration_timer for auction", %{auction: auction} do
    assert {:ok, _pid} = AuctionTimer.start_link({auction.id, auction.decision_duration, :decision_duration})
    ref = AuctionTimer.timer_ref(auction.id, :decision_duration)
    assert round(Float.round(Process.read_timer(ref) / 10) * 10) == auction.decision_duration

    :timer.sleep(500)
    assert Process.read_timer(ref) < auction.decision_duration
  end

  test "auction_timer is supervised", %{auction: auction} do
    {:ok, pid} = Oceanconnect.Auctions.TimersSupervisor.start_timer({auction.id, auction.duration, :duration})
    assert Process.alive?(pid)

    Process.exit(pid, :shutdown)

    refute Process.alive?(pid)
    :timer.sleep(500)

    {:ok, new_pid} = AuctionTimer.find_pid(auction.id, :duration)
    assert Process.alive?(new_pid)
  end
end
