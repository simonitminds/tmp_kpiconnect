defmodule Oceanconnect.Auctions.AuctionStoreTest do
  use Oceanconnect.DataCase
  alias Oceanconnect.Utilities
  alias Oceanconnect.Auctions.AuctionStore
  alias Oceanconnect.Auctions.AuctionStore.{AuctionCommand, AuctionState}

  setup do
    auction = insert(:auction, duration: 1_000)
    {:ok, %{auction: auction}}
  end

  test "starting auction_store for auction", %{auction: auction} do
    Oceanconnect.Auctions.AuctionsSupervisor.start_child(auction.id)
    assert AuctionStore.get_current_state(auction) == %AuctionState{status: :pending, auction_id: auction.id}

    current = DateTime.utc_now()

    auction
    |> AuctionCommand.start_auction
    |> AuctionStore.process_command(auction.id)

    expected_state = %AuctionState{status: :open, auction_id: auction.id, time_remaining: auction.duration, current_server_time: current}
    actual_state = AuctionStore.get_current_state(auction)

    assert Utilities.trunc_times(expected_state) == Utilities.trunc_times(actual_state)
  end

  test "auction is supervised", %{auction: auction} do
    Oceanconnect.Auctions.AuctionsSupervisor.start_child(auction.id)
    {:ok, pid} = AuctionStore.find_pid(auction.id)
    assert Process.alive?(pid)

    Process.exit(pid, :shutdown)

    refute Process.alive?(pid)
    :timer.sleep(500)

    {:ok, new_pid} = AuctionStore.find_pid(auction.id)
    assert Process.alive?(new_pid)
  end

  test "auction status is decision after duration timeout", %{auction: auction} do
    Oceanconnect.Auctions.AuctionsSupervisor.start_child(auction.id)
    assert AuctionStore.get_current_state(auction) == %AuctionState{status: :pending, auction_id: auction.id}
    current = DateTime.utc_now()

    auction
    |> AuctionCommand.start_auction
    |> AuctionStore.process_command(auction.id)

    assert AuctionStore.get_current_state(auction).status == :open

    :timer.sleep(1_100)

    expected_state =  %AuctionState{status: :decision, auction_id: auction.id, time_remaining: 0, current_server_time: current}
    actual_state = AuctionStore.get_current_state(auction)
    assert Utilities.trunc_times(expected_state) == Utilities.trunc_times(actual_state)
  end
end
