defmodule Oceanconnect.Auctions.AuctionStoreTest do
  use Oceanconnect.DataCase
  alias Oceanconnect.Auctions.AuctionStore
  alias Oceanconnect.Auctions.AuctionStore.{AuctionCommand, AuctionState}

  setup do
    auction = insert(:auction)
    Oceanconnect.Auctions.AuctionsSupervisor.start_child(auction.id)
    {:ok, %{auction: auction}}
  end

  test "starting auction_store for auction", %{auction: auction} do
    assert AuctionStore.get_current_state(auction) == %AuctionState{status: :pending, auction_id: auction.id}

    command = AuctionCommand.start_auction(auction)
    AuctionStore.process_command(command, auction.id)

    assert %AuctionState{status: :open, auction_id: auction.id} == AuctionStore.get_current_state(auction)
  end

  test "auction is supervised", %{auction: auction} do
   {:ok, pid} = AuctionStore.find_pid(auction.id)
    assert Process.alive?(pid)

    Process.exit(pid, :shutdown)

    refute Process.alive?(pid)
    :timer.sleep(500)

    {:ok, new_pid} = AuctionStore.find_pid(auction.id)
    assert Process.alive?(new_pid)
  end
end
