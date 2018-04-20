defmodule Oceanconnect.Auctions.AuctionEventStoreTest do
  use Oceanconnect.DataCase
  alias Oceanconnect.Auctions
  alias Oceanconnect.Auctions.{Auction, AuctionCache, AuctionEventStore, AuctionEventStorage, AuctionStore, AuctionSupervisor}

  setup do
    supplier_company = insert(:company)
    supplier2_company = insert(:company)
    auction = insert(:auction, duration: 1_000, decision_duration: 1_000, suppliers: [supplier_company, supplier2_company])
    |> Auctions.create_supplier_aliases
    |> Auctions.fully_loaded

    {:ok, _pid} = start_supervised({AuctionSupervisor, auction})
    Oceanconnect.FakeEventStorage.FakeEventStorageCache.start_link()

    {:ok, %{auction: auction}}
  end

  test "rebuild auction state from event storage", %{auction: auction = %Auction{id: auction_id}} do
    Auctions.start_auction(auction)
    bid = Auctions.place_bid(auction, %{"amount" => 1.25}, hd(auction.suppliers).id)
    Auctions.place_bid(auction, %{"amount" => 1.50}, hd(auction.suppliers).id)
    Auctions.end_auction(auction)
    Auctions.select_winning_bid(bid, "Winner Winner Chicken Dinner.")

    current_cache = AuctionCache.read(auction.id)
    current_state = AuctionStore.get_current_state(auction)
    current_bids = Auctions.AuctionBidList.get_bid_list(auction.id)
    current_event_list = AuctionEventStore.event_list(auction)

    # Crash AuctionStore / AuctionSupervisor and let restart
    {:ok, pid} = AuctionStore.find_pid(auction.id)
    Process.exit(pid, :shutdown)
    refute Process.alive?(pid)
    :timer.sleep(500)
    {:ok, new_pid} = AuctionStore.find_pid(auction.id)
    refute pid == new_pid

    assert current_cache == AuctionCache.read(auction.id)
    assert current_state == AuctionStore.get_current_state(auction)
    assert current_bids == Auctions.AuctionBidList.get_bid_list(auction.id)
    assert current_event_list == AuctionEventStore.event_list(auction)
  end
end
