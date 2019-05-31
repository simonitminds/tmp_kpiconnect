defmodule Oceanconnect.Auctions.FinalizedAuctionCacheTest do
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

  describe "when an auction reaches a final status" do
    setup do
      buyer_company = insert(:company)
      buyer = insert(:user, company: buyer_company)
      auction = insert(:auction, buyer: buyer_company) |> Auctions.fully_loaded()
      {:ok, _pid} = Auctions.AuctionsSupervisor.start_child(auction)

      {:ok, %{auction: auction, buyer: buyer}}
    end

    test "expired auctions create an entry in the finalized state cache", %{auction: auction} do
      {:ok, _pid} = FinalizedStateCache.start_link()
      :timer.sleep(500)

      auction
      |> Auctions.start_auction()
      |> Auctions.end_auction()
      |> Auctions.expire_auction()

      :timer.sleep(500)

      assert {:error, "Auction Store Not Started"} = Auctions.AuctionStore.find_pid(auction.id)
      assert {:ok, %{status: :expired}} = Auctions.FinalizedStateCache.for_auction(auction)
    end

    test "canceled auctions auctions create an entry in the finalized state cache", %{
      auction: auction,
      buyer: buyer
    } do
      {:ok, _pid} = FinalizedStateCache.start_link()

      auction
      |> Auctions.start_auction()
      |> Auctions.cancel_auction(buyer)

      :timer.sleep(500)

      assert {:error, "Auction Store Not Started"} = Auctions.AuctionStore.find_pid(auction.id)
      assert {:ok, %{status: :canceled}} = Auctions.FinalizedStateCache.for_auction(auction)
    end
  end

  describe "when an auction closes" do
    setup do
      supplier_company = insert(:company)
      supplier2_company = insert(:company)
      buyer_company = insert(:company, is_supplier: false)
      supplier = insert(:user, company: supplier_company)
      supplier2 = insert(:user, company: supplier2_company)

      vessel_fuel = insert(:vessel_fuel)

      auction =
        insert(
          :auction,
          duration: 1_000,
          decision_duration: 1_000,
          suppliers: [supplier_company, supplier2_company],
          buyer: buyer_company,
          auction_vessel_fuels: [vessel_fuel]
        )
        |> Auctions.fully_loaded()

      {:ok, _pid} = Auctions.AuctionsSupervisor.start_child(auction)

      vessel_fuel_id = "#{vessel_fuel.id}"
      Auctions.start_auction(auction)

      bid =
        create_bid(1.25, nil, supplier_company.id, vessel_fuel_id, auction)
        |> Auctions.place_bid(supplier)

      :timer.sleep(200)

      bid2 =
        create_bid(1.25, nil, supplier2_company.id, vessel_fuel_id, auction)
        |> Auctions.place_bid(supplier2)

      :timer.sleep(200)
      Auctions.end_auction(auction)

      {:ok, %{auction: auction, vessel_fuel: vessel_fuel, bid: bid, bid2: bid2}}
    end

    test "selecting a winning_solution finalizes the auction and creates an entry in the finalized state cache",
         %{
           auction: auction,
           bid: bid,
           vessel_fuel: vessel_fuel
         } do
      {:ok, _pid} = FinalizedStateCache.start_link()
      :timer.sleep(500)

      auction_id = auction.id
      auction_state = Auctions.get_auction_state!(auction)

      Auctions.select_winning_solution(
        [bid],
        auction_state.product_bids,
        auction,
        "you win",
        "Agent 9"
      )

      :timer.sleep(500)

      assert {:error, "Auction Store Not Started"} = Auctions.AuctionStore.find_pid(auction_id)
      assert {:ok, state} = Auctions.FinalizedStateCache.for_auction(auction)
    end
  end
end
