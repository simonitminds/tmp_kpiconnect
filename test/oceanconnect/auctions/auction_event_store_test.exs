defmodule Oceanconnect.Auctions.AuctionEventStoreTest do
  use Oceanconnect.DataCase
  alias Oceanconnect.Auctions

  alias Oceanconnect.Auctions.{
    Auction,
    AuctionCache,
    AuctionEvent,
    AuctionEventStore,
    AuctionStore,
    AuctionSupervisor
  }

  setup do
    supplier_company = insert(:company)
    supplier2_company = insert(:company)
    buyer_company = insert(:company, is_supplier: false)

    auction =
      insert(
        :auction,
        duration: 1_000,
        decision_duration: 60_000,
        suppliers: [supplier_company, supplier2_company],
        buyer: buyer_company
      )
      |> Auctions.create_supplier_aliases()
      |> Auctions.fully_loaded()

    {:ok, _pid} =
      start_supervised(
        {AuctionSupervisor,
         {auction,
          %{
            exclude_children: [
              :auction_reminder_timer,
              :auction_scheduler,
              :auction_event_handler
            ]
          }}}
      )

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
    current_event_list = AuctionEventStore.event_list(auction_id)

    # # Crash AuctionStore / AuctionSupervisor and let restart
    {:ok, pid} = AuctionStore.find_pid(auction_id)
    Process.exit(pid, :shutdown)
    refute Process.alive?(pid)
    :timer.sleep(500)
    {:ok, new_pid} = AuctionStore.find_pid(auction_id)
    refute pid == new_pid

    :timer.sleep(500)
    assert current_cache == AuctionCache.read(auction_id)
    :timer.sleep(500)
    assert current_state == Auctions.get_auction_state!(auction)
    assert current_event_list == AuctionEventStore.event_list(auction_id)
  end

  test "rebuilding auction state emits a rebuilt event", %{
    auction: auction = %Auction{id: auction_id}
  } do
    :ok = Phoenix.PubSub.subscribe(:auction_pubsub, "auction:#{auction_id}")
    Auctions.start_auction(auction)
    Auctions.place_bid(auction, %{"amount" => 1.50}, hd(auction.suppliers).id)
    Auctions.end_auction(auction)
    :timer.sleep(500)
    # # Crash AuctionStore / AuctionSupervisor and let restart
    {:ok, pid} = AuctionStore.find_pid(auction_id)
    Process.exit(pid, :shutdown)
    refute Process.alive?(pid)
    :timer.sleep(500)
    {:ok, new_pid} = AuctionStore.find_pid(auction_id)
    refute pid == new_pid
    :timer.sleep(1_000)

    assert_received %AuctionEvent{type: :auction_state_rebuilt, auction_id: ^auction_id}

    assert %AuctionEvent{
             type: :auction_state_rebuilt,
             data: %{state: _state, time_remaining: time_remaining}
           } = hd(AuctionEventStore.event_list(auction_id))

    assert Oceanconnect.Utilities.round_time_remaining(time_remaining) ==
             auction.decision_duration
  end

  test "ensure decision_duration timer is canceled when rebuilding expired auction", %{
    auction: auction = %Auction{id: auction_id}
  } do
    auction
    |> Auctions.start_auction()
    |> Auctions.end_auction()
    |> Auctions.expire_auction()

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
