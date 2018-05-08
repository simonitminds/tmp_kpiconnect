defmodule Oceanconnect.Auctions.AuctionSchedulerTest do
  use Oceanconnect.DataCase
  alias Oceanconnect.Auctions
  alias Oceanconnect.Auctions.{Auction, AuctionEvent, AuctionSupervisor}

  setup do
    now = DateTime.utc_now()
    start = Map.put(now, :second, now.second + 2)
    auction = insert(:auction, auction_start: start)
    {:ok, _pid} = start_supervised({AuctionSupervisor, {auction, %{handle_events: true}}})
    {:ok, %{auction: auction}}
  end

  test "start auction based on scheduler", %{auction: auction = %Auction{id: auction_id}} do
    assert :ok = Phoenix.PubSub.subscribe(:auction_pubsub, "auction:#{auction_id}")
    assert Auctions.get_auction_state!(auction).status == :pending
    receive do
      %AuctionEvent{type: :auction_started, auction_id: ^auction_id, data: %{}} ->
          assert true
      any -> IO.inspect any
    after
      5000 ->
        assert false, "Expected message received nothing."
    end
  end

  # test "cancel_timer/2 cancels the specified timer", %{auction: auction} do
  #   Oceanconnect.Auctions.start_auction(auction)
  #   refute AuctionTimer.timer_ref(auction.id, :duration) == false
  #
  #   AuctionTimer.cancel_timer(auction.id, :duration)
  #   assert AuctionTimer.timer_ref(auction.id, :duration) == false
  # end
  #
  # test "cancel_timer/2 gracefully continues if timer doesn't exist", %{auction: auction} do
  #   AuctionTimer.cancel_timer(auction.id, :duration)
  #   assert AuctionTimer.timer_ref(auction.id, :duration) == false
  # end
end
