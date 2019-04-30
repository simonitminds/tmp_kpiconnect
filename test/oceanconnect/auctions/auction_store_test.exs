defmodule Oceanconnect.Auctions.AuctionStoreTest do
  use Oceanconnect.DataCase
  alias Oceanconnect.Auctions

  alias Oceanconnect.Auctions.{
    AuctionPayload,
    AuctionStore,
    AuctionSupervisor,
    Solution,
    AuctionStore.AuctionState
  }

  setup do
    supplier_company = insert(:company)
    supplier2_company = insert(:company)
    buyer_company = insert(:company, is_supplier: false)
    buyer = insert(:user, company: buyer_company)
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

    {:ok,
     %{
       auction: auction,
       buyer: buyer,
       supplier_company: supplier_company,
       supplier2_company: supplier2_company,
       vessel_fuel: vessel_fuel,
       supplier: supplier,
       supplier2: supplier2
     }}
  end

  test "draft status of draft auction" do
    auction_attrs =
      insert(:auction)
      |> Map.take([:port_id, :vessel_id])

    {:ok, auction} = Auctions.create_auction(auction_attrs)
    # create_action has the side effect of starting the AuctionsSupervisor, thus the sleep
    :timer.sleep(100)

    assert :draft == Auctions.get_auction_state!(auction).status
  end

  test "pending status of schedulable auction" do
    auction_attrs =
      insert(:auction)
      |> Map.drop([:__struct__, :id, :buyer, :fuel, :port, :suppliers, :vessel])

    {:ok, auction} = Auctions.create_auction(auction_attrs)
    # create_action has the side effect of starting the AuctionsSupervisor, thus the sleep
    :timer.sleep(100)

    assert :pending == Auctions.get_auction_state!(auction).status
  end

  test "starting auction_store for auction", %{auction: auction} do
    assert AuctionStore.get_current_state(auction) == AuctionState.from_auction(auction)

    Oceanconnect.Auctions.start_auction(auction)

    expected_state =
      auction
      |> AuctionState.from_auction()
      |> Map.merge(%{status: :open, auction_id: auction.id})

    actual_state = AuctionStore.get_current_state(auction)

    assert expected_state == actual_state
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

  test "auction status is decision after duration timeout", %{auction: auction} do
    Auctions.start_auction(auction)
    :timer.sleep(300)

    assert AuctionStore.get_current_state(auction).status == :open
    # Need to sleep longer than the auction duration (1000ms)
    :timer.sleep(1_000)

    expected_state =
      auction
      |> AuctionState.from_auction()
      |> Map.merge(%{status: :decision, auction_id: auction.id})

    actual_state = AuctionStore.get_current_state(auction)

    assert expected_state == actual_state
  end

  test "auction decision period expiring", %{auction: auction} do
    auction
    |> Auctions.start_auction()
    |> Auctions.end_auction()
    |> Auctions.expire_auction()

    expected_state =
      auction
      |> AuctionState.from_auction()
      |> Map.merge(%{status: :expired, auction_id: auction.id})

    actual_state = AuctionStore.get_current_state(auction)

    assert expected_state == actual_state
  end

  test "expired auctions create an entry in the finalized state cache", %{auction: auction} do
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
    auction
    |> Auctions.start_auction()
    |> Auctions.cancel_auction(buyer)

    :timer.sleep(500)

    assert {:error, "Auction Store Not Started"} = Auctions.AuctionStore.find_pid(auction.id)
    assert {:ok, %{status: :canceled}} = Auctions.FinalizedStateCache.for_auction(auction)
  end

  describe "lowest bid list" do
    setup %{
      auction: auction,
      supplier_company: supplier_company,
      vessel_fuel: vessel_fuel,
      supplier: supplier
    } do
      Auctions.start_auction(auction)
      vessel_fuel_id = "#{vessel_fuel.id}"

      bid =
        create_bid(1.25, nil, supplier_company.id, vessel_fuel_id, auction)
        |> Auctions.place_bid(supplier)

      {:ok, %{bid: bid, vessel_fuel_id: vessel_fuel_id}}
    end

    test "first bid is added and extends duration", %{
      auction: auction,
      bid: bid,
      vessel_fuel_id: vessel_fuel_id
    } do
      auction_payload = AuctionPayload.get_auction_payload!(auction, auction.buyer_id)

      %{lowest_bids: lowest_bids} = auction_payload.product_bids[vessel_fuel_id]
      bid_id = bid.id
      assert [%{id: ^bid_id}] = lowest_bids
      assert auction_payload.time_remaining > 2 * 60_000
    end

    test "matching bid is added and extends duration", %{
      auction: auction,
      bid: bid,
      supplier2_company: supplier2_company,
      supplier2: supplier2,
      vessel_fuel_id: vessel_fuel_id
    } do
      :timer.sleep(1_100)

      new_bid =
        create_bid(bid.amount, nil, supplier2_company.id, vessel_fuel_id, auction)
        |> Auctions.place_bid(supplier2)

      auction_payload = AuctionPayload.get_auction_payload!(auction, auction.buyer_id)
      %{lowest_bids: lowest_bids} = auction_payload.product_bids[vessel_fuel_id]

      assert Enum.all?(lowest_bids, fn lowest_bid ->
               lowest_bid.id in [bid.id, new_bid.id]
             end)

      assert auction_payload.time_remaining > 3 * 60_000 - 1_000
    end

    test "new lowest bid is added and extends duration", %{
      auction: auction,
      bid: bid,
      supplier: supplier,
      vessel_fuel_id: vessel_fuel_id
    } do
      :timer.sleep(1_100)

      new_bid =
        create_bid(bid.amount - 1, nil, bid.supplier_id, vessel_fuel_id, auction)
        |> Auctions.place_bid(supplier)

      auction_payload = AuctionPayload.get_auction_payload!(auction, auction.buyer_id)
      %{lowest_bids: lowest_bids} = auction_payload.product_bids[vessel_fuel_id]

      assert Enum.all?(lowest_bids, fn lowest_bid ->
               lowest_bid.id in [new_bid.id]
             end)

      assert auction_payload.time_remaining > 3 * 60_000 - 1_000
    end

    test "lowest (and only) bidder raises bid and duration extends", %{
      auction: auction,
      bid: bid,
      supplier: supplier,
      vessel_fuel_id: vessel_fuel_id
    } do
      :timer.sleep(1_100)
      increased_bid_amount = bid.amount + 1

      create_bid(increased_bid_amount, nil, bid.supplier_id, vessel_fuel_id, auction)
      |> Auctions.place_bid(supplier)

      auction_payload = AuctionPayload.get_auction_payload!(auction, auction.buyer_id)
      %{lowest_bids: lowest_bids} = auction_payload.product_bids[vessel_fuel_id]
      lowest_bid = hd(lowest_bids)

      assert increased_bid_amount == lowest_bid.amount
      assert auction_payload.time_remaining > 3 * 60_000 - 1_000
    end

    test "lowest bidder raises bid above next lowest bidder and duration does not extend", %{
      auction: auction,
      bid: bid,
      supplier2_company: supplier2_company,
      supplier2: supplier2,
      supplier: supplier,
      vessel_fuel_id: vessel_fuel_id
    } do
      create_bid(bid.amount + 0.5, nil, supplier2_company.id, vessel_fuel_id, auction)
      |> Auctions.place_bid(supplier2)

      :timer.sleep(1_100)

      create_bid(bid.amount + 0.5, nil, bid.supplier_id, vessel_fuel_id, auction)
      |> Auctions.place_bid(supplier)

      auction_payload = AuctionPayload.get_auction_payload!(auction, auction.buyer_id)
      %{lowest_bids: lowest_bids} = auction_payload.product_bids[vessel_fuel_id]
      lowest_bid = hd(lowest_bids)
      other_lowest_bid = bid.amount + 0.5

      assert ^other_lowest_bid = lowest_bid.amount
      assert auction_payload.time_remaining < 3 * 60_000 - 1_000
    end

    test "new lowest bid is placed and minimum bid is activated and duration extends", %{
      auction: auction,
      supplier_company: supplier_company,
      supplier: supplier,
      supplier2_company: supplier2_company,
      supplier2: supplier2,
      vessel_fuel_id: vessel_fuel_id
    } do
      :timer.sleep(1_100)

      create_bid(1.00, 0.50, supplier_company.id, vessel_fuel_id, auction)
      |> Auctions.place_bid(supplier)

      create_bid(0.75, nil, supplier2_company.id, vessel_fuel_id, auction)
      |> Auctions.place_bid(supplier2)

      auction_payload = AuctionPayload.get_auction_payload!(auction, auction.buyer_id)
      %{lowest_bids: lowest_bids} = auction_payload.product_bids[vessel_fuel_id]
      lowest_bid = hd(lowest_bids)

      assert lowest_bid.amount == 0.50
      assert lowest_bid.supplier == supplier_company.name
      assert auction_payload.time_remaining > 3 * 60_000 - 1_000
    end
  end

  describe "winning solution" do
    setup %{
      auction: auction,
      supplier_company: supplier_company,
      supplier: supplier,
      supplier2_company: supplier2_company,
      supplier2: supplier2,
      vessel_fuel: vessel_fuel
    } do
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

      {:ok, %{bid: bid, bid2: bid2}}
    end

    test "winning solution can be selected", %{
      auction: auction,
      bid: bid,
      vessel_fuel: vessel_fuel
    } do
      auction_id = auction.id
      vessel_fuel_id = "#{vessel_fuel.id}"
      bid_id = bid.id

      auction_state = Auctions.get_auction_state!(auction)

      Auctions.select_winning_solution(
        [bid],
        auction_state.product_bids,
        auction,
        "you win",
        "Agent 9"
      )

      auction_payload = AuctionPayload.get_auction_payload!(auction, auction.buyer_id)

      assert %Solution{
               auction_id: ^auction_id,
               bids: [
                 %{id: ^bid_id, amount: 1.25, vessel_fuel_id: ^vessel_fuel_id}
               ],
               comment: "you win"
             } = auction_payload.solutions.winning_solution
    end

    test "selecting a winning_solution finalizes the auction and creates an entry in the finalized state cache",
         %{
           auction: auction,
           bid: bid,
           vessel_fuel: vessel_fuel
         } do
      auction_id = auction.id
      vessel_fuel_id = "#{vessel_fuel.id}"
      bid_id = bid.id

      auction_state = Auctions.get_auction_state!(auction)

      Auctions.select_winning_solution(
        [bid],
        auction_state.product_bids,
        auction,
        "you win",
        "Agent 9"
      )

      :timer.sleep(1000)

      assert {:error, "Auction Store Not Started"} = Auctions.AuctionStore.find_pid(auction_id)
      assert {:ok, state} = Auctions.FinalizedStateCache.for_auction(auction)
    end
  end
end
