defmodule Oceanconnect.Auctions.AuctionCacheTest do
  use Oceanconnect.DataCase
  alias Oceanconnect.Auctions

  alias Oceanconnect.Auctions.{
    FinalizedStateCache,
    FinalizedStateCacheSupervisor,
    AuctionSupervisor,
    AuctionStore.AuctionState
  }

  setup do
    buyer_company = insert(:company)
    supplier = insert(:company, is_supplier: true)
    supplier_2 = insert(:company, is_supplier: true)

    auction =
      insert(:auction, buyer: buyer_company, suppliers: [supplier, supplier_2])
      |> Auctions.fully_loaded()

    Supervisor.terminate_child(FinalizedStateCacheSupervisor, FinalizedStateCache)

    {:ok, _pid} =
      start_supervised(
        {AuctionSupervisor,
         {auction,
          %{
            exclude_children: [
              :auction_reminder_timer,
              :auction_scheduler
            ]
          }}}
      )

    {:ok, %{auction: auction}}
  end

  describe "starting the cache" do
    test "creates entries for closed, canceled and expired auctions" do
      closed_auction =
        insert(:auction,
          auction_closed_time: DateTime.utc_now(),
          auction_ended: DateTime.utc_now()
        )

      close_auction!(closed_auction)

      {:ok, _pid} = FinalizedStateCache.start_link()
      :timer.sleep(2_000)

      assert {:ok, closed_state} = FinalizedStateCache.for_auction(closed_auction)
    end

    test "does not add non closed auctions" do
      closed_auction =
        insert(:auction,
          auction_closed_time: DateTime.utc_now(),
          auction_ended: DateTime.utc_now()
        )

      close_auction!(closed_auction)

      open_auction = insert(:auction)
      start_auction!(open_auction)

      {:ok, _pid} = FinalizedStateCache.start_link()
      :timer.sleep(2_000)

      assert {:error, "No Entry for Auction"} = FinalizedStateCache.for_auction(open_auction)
      assert {:ok, closed_state} = FinalizedStateCache.for_auction(closed_auction)
    end
  end

  describe "add_auction/2" do
    test "adding an auction", %{auction: auction} do
      {:ok, _pid} = FinalizedStateCache.start_link()
      state = AuctionState.from_auction(auction)
      FinalizedStateCache.add_auction(auction, %{state | status: :closed})

      assert {:ok, state} = FinalizedStateCache.for_auction(auction)
    end

    test "adding a non finalized auction", %{auction: auction} do
      {:ok, _pid} = FinalizedStateCache.start_link()
      state = AuctionState.from_auction(auction)

      assert {:error, "Cannot Add Non Finalized Auction"} =
               FinalizedStateCache.add_auction(auction, %{state | status: :open})
    end

    test "adding an auction when finalized state cache is down", %{auction: auction} do
      state = AuctionState.from_auction(auction)

      assert {:error, "Finalized State Cache Not Started"} =
               FinalizedStateCache.add_auction(auction, %{state | status: :closed})
    end
  end

  describe "for_auction/1" do
    test "when cached", %{auction: auction} do
      {:ok, _pid} = FinalizedStateCache.start_link()
      state = AuctionState.from_auction(auction)
      FinalizedStateCache.add_auction(auction, %{state | status: :closed})

      assert {:ok, state} = FinalizedStateCache.for_auction(auction)
    end

    test "when not cached", %{auction: auction} do
      {:ok, _pid} = FinalizedStateCache.start_link()

      assert {:error, "No Entry for Auction"} = FinalizedStateCache.for_auction(auction)
    end
  end
end
