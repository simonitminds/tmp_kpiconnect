defmodule Oceanconnect.Auctions.AuctionStoreTest do
  use Oceanconnect.DataCase
  alias Oceanconnect.Auctions
  alias Oceanconnect.Auctions.{AuctionBidList, AuctionPayload, AuctionStore, AuctionSupervisor}
  alias Oceanconnect.Auctions.AuctionStore.{AuctionState}

  setup do
    supplier_company = insert(:company)
    supplier2_company = insert(:company)
    auction = insert(:auction, duration: 1_000, decision_duration: 1_000,
                      suppliers: [supplier_company, supplier2_company])
    {:ok, _pid} = start_supervised({AuctionSupervisor, {auction, %{exclude_children: [:auction_scheduler]}}})
    on_exit(fn ->
      case DynamicSupervisor.which_children(Oceanconnect.Auctions.AuctionsSupervisor) do
        [] -> nil
        children ->
          Enum.map(children, fn({_, pid, _, _}) ->
            Process.unlink(pid)
            Process.exit(pid, :shutdown)
          end)
      end
    end)
    {:ok, %{auction: auction, supplier_company: supplier_company, supplier2_company: supplier2_company}}
  end

  describe "process_new_bid/2" do
    setup %{auction: auction, supplier_company: supplier_company, supplier2_company: supplier2_company} do
      bid_params = %{
        "amount" => 2.50,
        "min_amount" => 2.00,
        "supplier_id" => supplier_company.id,
        "time_entered" => DateTime.utc_now()
      }
      bid = AuctionBidList.AuctionBid.from_params_to_auction_bid(bid_params, auction)
      bid_params2 = %{
        "amount" => 2.25,
        "min_amount" => nil,
        "supplier_id" => supplier2_company.id,
        "time_entered" => DateTime.utc_now()
      }
      bid2 = AuctionBidList.AuctionBid.from_params_to_auction_bid(bid_params2, auction)
      {:ok, %{bid: bid, bid2: bid2}}
    end

    test "autobid not triggered when a new lowest bid is placed when auction pending", %{auction: auction, bid: bid, bid2: bid2} do
      current_state = %AuctionState{
        auction_id: auction.id,
        status: :pending,
        lowest_bids: [bid],
        minimum_bids: [bid]
      }

      {lowest_bid, _supplier_first_bid, updated_state} = AuctionStore.process_new_bid(bid2, current_state)
      refute lowest_bid
      assert updated_state.lowest_bids == [bid2, bid]
      assert updated_state.minimum_bids == [bid, bid2]
    end

    test "autobid is placed when a new lowest bid is placed when auction open", %{auction: auction, bid: bid, bid2: bid2} do
      current_state = %AuctionState{
        auction_id: auction.id,
        status: :open,
        lowest_bids: [bid],
        minimum_bids: [bid]
      }
      expected_lowest = bid2
      |> Map.put(:supplier_id, bid.supplier_id)
      |> Map.put(:amount, 2.00)

      {lowest_bid, supplier_first_bid, updated_state} = AuctionStore.process_new_bid(bid2, current_state)
      refute lowest_bid
      assert supplier_first_bid
      assert updated_state.lowest_bids == [expected_lowest]
    end

    test "minimum bid war is triggered when auction open", %{auction: auction, bid: bid, bid2: bid2} do
      current_state = %AuctionState{
        auction_id: auction.id,
        status: :open,
        lowest_bids: [bid],
        minimum_bids: [bid]
      }
      updated_bid2 = bid2
      |> Map.put(:min_amount, 2.00)

      {lowest_bid?, _supplier_first_bid, updated_state} = AuctionStore.process_new_bid(updated_bid2, current_state)
      first_bid = updated_state.lowest_bids |> hd
      second_bid = updated_state.lowest_bids |> List.last

      refute lowest_bid?
      IO.inspect(updated_state.lowest_bids)
      assert [first_bid.amount, first_bid.supplier_id] == [2.00, bid.supplier_id]
      assert [second_bid.amount, second_bid.supplier_id] == [2.00, bid2.supplier_id]
      assert updated_state.minimum_bids == [bid, updated_bid2]
    end
  end

  test "draft status of draft auction" do
    auction_attrs = insert(:auction)
    |> Map.take([:eta, :port_id, :vessel_id])
    {:ok, auction} = Auctions.create_auction(auction_attrs)

    assert :draft == Auctions.get_auction_state!(auction).status
  end

  test "pending status of schedulable auction" do
    auction_attrs = insert(:auction)
    |> Map.drop([:__struct__, :id, :buyer, :fuel, :port, :suppliers, :vessel])
    {:ok, auction} = Auctions.create_auction(auction_attrs)

    assert :pending == Auctions.get_auction_state!(auction).status
  end

  test "starting auction_store for auction", %{auction: auction} do
    assert AuctionStore.get_current_state(auction) == AuctionState.from_auction(auction)

    Oceanconnect.Auctions.start_auction(auction)

    expected_state = auction
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
    :timer.sleep(500)

    assert AuctionStore.get_current_state(auction).status == :open

    :timer.sleep(1_000)

    expected_state = auction
    |> AuctionState.from_auction
    |> Map.merge(%{status: :decision, auction_id: auction.id})
    actual_state = AuctionStore.get_current_state(auction)

    assert expected_state == actual_state
  end

  test "auction decision period expiring", %{auction: auction} do
    auction
    |> Auctions.start_auction
    |> Auctions.end_auction
    |> Auctions.expire_auction

    expected_state = auction
    |> AuctionState.from_auction
    |> Map.merge(%{status: :expired, auction_id: auction.id})
    actual_state = AuctionStore.get_current_state(auction)

    assert expected_state == actual_state
  end

  describe "lowest bid list" do
    setup %{auction: auction, supplier_company: supplier_company} do
      Auctions.start_auction(auction)
      bid = Auctions.place_bid(auction, %{"amount" => 1.25}, supplier_company.id)
      {:ok, %{bid: bid}}
    end

    test "first bid is added and extends duration", %{auction: auction, bid: bid} do
      auction_payload = AuctionPayload.get_auction_payload!(auction, auction.buyer_id)

      assert Enum.all?(auction_payload.state.lowest_bids, fn(lowest_bid) ->
        lowest_bid.id in [bid.id]
      end)
      assert auction_payload.time_remaining > 2 * 60_000
    end

    test "matching bid is added and extends duration", %{auction: auction, bid: bid} do
      :timer.sleep(1_100)
      new_bid = Auctions.place_bid(auction, %{"amount" => bid.amount}, bid.supplier_id)
      auction_payload = AuctionPayload.get_auction_payload!(auction, auction.buyer_id)

      assert Enum.all?(auction_payload.state.lowest_bids, fn(lowest_bid) ->
        lowest_bid.id in [bid.id, new_bid.id]
      end)
      assert auction_payload.time_remaining > 3 * 60_000 - 1_000
    end

    test "new lowest bid is added and extends duration", %{auction: auction, bid: bid} do
      :timer.sleep(1_100)
      new_bid = Auctions.place_bid(auction, %{"amount" => bid.amount - 1}, bid.supplier_id)
      auction_payload = AuctionPayload.get_auction_payload!(auction, auction.buyer_id)

      assert Enum.all?(auction_payload.state.lowest_bids, fn(lowest_bid) ->
        lowest_bid.id in [new_bid.id]
      end)
      assert auction_payload.time_remaining > 3 * 60_000 - 1_000
    end

    test "non-lowest bid is not added and duration does not extend", %{auction: auction, bid: bid} do
      :timer.sleep(1_100)
      Auctions.place_bid(auction, %{"amount" => bid.amount + 1}, bid.supplier_id)
      auction_payload = AuctionPayload.get_auction_payload!(auction, auction.buyer_id)

      assert Enum.all?(auction_payload.state.lowest_bids, fn(lowest_bid) ->
        lowest_bid.id in [bid.id]
      end)
      assert auction_payload.time_remaining < 3 * 60_000 - 1_000
    end

    test "new lowest bid is placed and minimum bid is activated and duration extends", %{auction: auction, supplier_company: supplier_company, supplier2_company: supplier2_company} do
      :timer.sleep(1_100)
      Auctions.place_bid(auction, %{"amount" => 1.00, "min_amount" => 0.50}, supplier_company.id)
      Auctions.place_bid(auction, %{"amount" => 0.75}, supplier2_company.id)

      auction_payload = AuctionPayload.get_auction_payload!(auction, auction.buyer_id)

      assert Enum.all?(auction_payload.state.lowest_bids, fn(lowest_bid) ->
        assert lowest_bid.amount == 0.75
        assert lowest_bid.supplier == supplier_company.name
      end)
      assert auction_payload.time_remaining > 3 * 60_000 - 1_000
    end
  end

  describe "winning bid" do
    setup %{auction: auction, supplier_company: supplier_company, supplier2_company: supplier2_company} do
      Auctions.start_auction(auction)
      bid = Auctions.place_bid(auction, %{"amount" => 1.25}, supplier_company.id)
      bid2 = Auctions.place_bid(auction, %{"amount" => 1.25}, supplier2_company.id)
      Auctions.end_auction(auction)

      {:ok, %{bid: bid, bid2: bid2}}
    end

    test "winning bid can be selected", %{auction: auction, bid: bid} do
      Auctions.select_winning_bid(bid, "test")
      auction_state = Auctions.get_auction_state!(auction)

      assert auction_state.winning_bid.id == bid.id
      assert auction_state.winning_bid.comment == "test"
      assert auction_state.status == :closed

      :timer.sleep(1_100)
      verify_decision_timer_cancelled = Auctions.get_auction_state!(auction)
      assert verify_decision_timer_cancelled.status == :closed
    end
  end
end
