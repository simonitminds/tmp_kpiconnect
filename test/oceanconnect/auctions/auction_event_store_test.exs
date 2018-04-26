defmodule Oceanconnect.Auctions.AuctionEventStoreTest do
  use Oceanconnect.DataCase
  alias Oceanconnect.Auctions
  alias Oceanconnect.Auctions.{Auction, AuctionCache, AuctionEventStore, AuctionStore, AuctionSupervisor}

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
    :timer.sleep(500)

    current_cache = AuctionCache.read(auction_id)
    current_state = Auctions.get_auction_state!(auction)
    current_bids = Auctions.AuctionBidList.get_bid_list(auction_id)
    current_event_list = AuctionEventStore.event_list(auction_id)

    # # Crash AuctionStore / AuctionSupervisor and let restart
    {:ok, pid} = AuctionStore.find_pid(auction_id)
    Process.exit(pid, :shutdown)
    refute Process.alive?(pid)
    :timer.sleep(500)
    {:ok, new_pid} = AuctionStore.find_pid(auction_id)
    refute pid == new_pid

    :timer.sleep(1_000)
    assert current_cache == AuctionCache.read(auction_id)
    assert current_state == Auctions.get_auction_state!(auction)
    assert current_bids == Auctions.AuctionBidList.get_bid_list(auction_id)
    assert current_event_list == AuctionEventStore.event_list(auction_id)
  end

  test "ensure decision_duration timer is canceled when rebuilding expired auction", %{auction: auction = %Auction{id: auction_id}} do
    auction
    |> Auctions.start_auction
    |> Auctions.end_auction
    |> Auctions.expire_auction

    current_state = Auctions.get_auction_state!(auction)
    current_event_list = AuctionEventStore.event_list(auction_id)

    # # Crash AuctionStore / AuctionSupervisor and let restart
    {:ok, pid} = AuctionStore.find_pid(auction_id)
    Process.exit(pid, :shutdown)
    refute Process.alive?(pid)
    :timer.sleep(500)
    {:ok, new_pid} = AuctionStore.find_pid(auction_id)
    refute pid == new_pid

    :timer.sleep(1_000)
    assert current_state == Auctions.get_auction_state!(auction)
    assert current_event_list == AuctionEventStore.event_list(auction_id)
  end
end
