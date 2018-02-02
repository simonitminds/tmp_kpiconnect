defmodule Oceanconnect.Auctions.AuctionTimerTest do
  use Oceanconnect.DataCase
  alias Oceanconnect.Auctions.AuctionTimer

  setup do
    auction = insert(:auction, duration: 15)
    {:ok, %{auction: auction}}
  end

  test "start auction_timer for auction", %{auction: auction} do
    assert {:ok, _pid} = AuctionTimer.start_link(auction.id)
    ref = AuctionTimer.timer_ref(auction.id)
    assert Process.read_timer(ref) == auction.duration * 60_000

    :timer.sleep(500)
    assert Process.read_timer(ref) < auction.duration * 60_000
  end

  test "auction_timer is supervised", %{auction: auction} do
    {:ok, pid} = Oceanconnect.Auctions.TimersSupervisor.start_timer(auction.id)
    assert Process.alive?(pid)

    Process.exit(pid, :shutdown)

    refute Process.alive?(pid)
    :timer.sleep(500)

    {:ok, new_pid} = AuctionTimer.find_pid(auction.id)
    assert Process.alive?(new_pid)
  end
end
