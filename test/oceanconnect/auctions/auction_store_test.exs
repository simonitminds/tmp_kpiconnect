defmodule Oceanconnect.Auctions.AuctionStoreTest do
  use Oceanconnect.DataCase
  alias Oceanconnect.Auctions.AuctionStore
  alias Oceanconnect.Auctions.AuctionStore.{AuctionCommand, AuctionState}

  setup do
    auction = insert(:auction)
    {:ok, auction_store} = AuctionStore.start_link(auction.id)
    {:ok, %{auction_store: auction_store, auction: auction}}
  end

  test "starting auction_store for auction", %{auction: auction} do
    assert AuctionStore.get_current_state(auction) == %AuctionState{status: :pending, auction_id: auction.id}

    command = AuctionCommand.start_auction(auction)
    AuctionStore.process_command(command)

    assert %AuctionState{status: :open, auction_id: auction.id} == AuctionStore.get_current_state(auction)
  end

end
