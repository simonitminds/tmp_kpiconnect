defmodule Oceanconnect.Auctions.AuctionStoreTest do
  use Oceanconnect.DataCase
  alias Oceanconnect.Utilities
  alias Oceanconnect.Auctions.{AuctionBidList, AuctionStore, Command}
  alias Oceanconnect.Auctions.AuctionStore.{AuctionState}

  setup do
    auction = insert(:auction, duration: 1_000, decision_duration: 1_000)
    Oceanconnect.Auctions.AuctionsSupervisor.start_child(auction)
    {:ok, %{auction: auction}}
  end

  test "starting auction_store for auction", %{auction: auction} do
    assert AuctionStore.get_current_state(auction) == AuctionState.from_auction(auction)

    current = DateTime.utc_now()

    auction
    |> Command.start_auction
    |> AuctionStore.process_command


    expected_state = auction
    |> AuctionState.from_auction()
    |> Map.merge(%{status: :open, auction_id: auction.id, time_remaining: auction.duration, current_server_time: current})
    actual_state = AuctionStore.get_current_state(auction)

    assert Utilities.trunc_times(expected_state) == Utilities.trunc_times(actual_state)
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
    assert AuctionStore.get_current_state(auction) == AuctionState.from_auction(auction)

    current = DateTime.utc_now()

    auction
    |> Command.start_auction
    |> AuctionStore.process_command

    AuctionStore.get_current_state(auction)

    assert AuctionStore.get_current_state(auction).status == :open

    :timer.sleep(1_000)

    expected_state = auction
    |> AuctionState.from_auction
    |> Map.merge(%{status: :decision, auction_id: auction.id, time_remaining: auction.decision_duration, current_server_time: current})
    actual_state = AuctionStore.get_current_state(auction)

    assert Utilities.trunc_times(expected_state) == Utilities.trunc_times(actual_state)
  end

  test "auction decision period ending", %{auction: auction} do
    auction
    |> Command.start_auction
    |> AuctionStore.process_command

    auction
    |> Command.end_auction
    |> AuctionStore.process_command

    auction
    |> Command.end_auction_decision_period
    |> AuctionStore.process_command

    current = DateTime.utc_now()

    expected_state = auction
    |> AuctionState.from_auction
    |> Map.merge(%{status: :closed, auction_id: auction.id, time_remaining: 0, current_server_time: current})
    actual_state = AuctionStore.get_current_state(auction)

    assert Utilities.trunc_times(expected_state) == Utilities.trunc_times(actual_state)
  end

  describe "winning bid list" do
    setup %{auction: auction} do
      bid = %{"amount" => "1.25"}
      |> Map.put("supplier_id", hd(auction.suppliers).id)
      |> Map.put("id", UUID.uuid4(:hex))
      |> Map.put("time_entered", DateTime.utc_now())
      |> AuctionBidList.AuctionBid.from_params_to_auction_bid(auction)

      auction
      |> Command.start_auction
      |> AuctionStore.process_command

      bid
      |> Command.process_new_bid
      |> AuctionStore.process_command
      {:ok, %{bid: bid}}
    end

    test "first bid is added and extends duration", %{auction: auction, bid: bid} do
      actual_state = AuctionStore.get_current_state(auction)

      assert [bid] == actual_state.winning_bid
      assert actual_state.time_remaining > 2 * 60_000
    end

    test "matching bid is added and extends duration", %{auction: auction, bid: bid} do
      new_bid = bid
      |> Map.merge(%{id: UUID.uuid4(:hex), time_entered: DateTime.utc_now()})

      new_bid
      |> Command.process_new_bid
      |> AuctionStore.process_command

      actual_state = AuctionStore.get_current_state(auction)

      assert [bid, new_bid] == actual_state.winning_bid
      assert actual_state.time_remaining > 2 * 60_000
    end

    test "non-winning bid is not added and duration does not extend", %{auction: auction, bid: bid} do
      new_bid = bid
      |> Map.merge(%{id: UUID.uuid4(:hex), time_entered: DateTime.utc_now(), amount: "1.50"})

      new_bid
      |> Command.process_new_bid
      |> AuctionStore.process_command

      :timer.sleep(1_100)
      actual_state = AuctionStore.get_current_state(auction)

      assert [bid] == actual_state.winning_bid
      assert actual_state.time_remaining < 3 * 60_000 - 1_000
    end

    test "new winning bid is added and extends duration", %{auction: auction, bid: bid} do
      new_bid = bid
      |> Map.merge(%{id: UUID.uuid4(:hex), time_entered: DateTime.utc_now(), amount: "0.75"})

      new_bid
      |> Command.process_new_bid
      |> AuctionStore.process_command

      actual_state = AuctionStore.get_current_state(auction)

      assert [new_bid] == actual_state.winning_bid
      assert actual_state.time_remaining > 2 * 60_000
    end
  end
end
