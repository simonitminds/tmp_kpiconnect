defmodule Oceanconnect.Auctions.AuctionStoreTest do
  use Oceanconnect.DataCase
  alias Oceanconnect.Auctions
  alias Oceanconnect.Auctions.{AuctionPayload, AuctionStore, Command}
  alias Oceanconnect.Auctions.AuctionStore.{AuctionState}

  setup do
    supplier_company = insert(:company)
    supplier2_company = insert(:company)
    auction = insert(:auction, duration: 1_000, decision_duration: 1_000,
                      suppliers: [supplier_company, supplier2_company])
    start_supervised({Oceanconnect.Auctions.AuctionSupervisor, auction.id})
    {:ok, %{auction: auction, supplier_company: supplier_company, supplier2_company: supplier2_company}}
  end

  test "starting auction_store for auction", %{auction: auction} do
    assert AuctionStore.get_current_state(auction) == AuctionState.from_auction(auction.id)

    Oceanconnect.Auctions.start_auction(auction)

    expected_state = auction.id
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
    assert AuctionStore.get_current_state(auction) == AuctionState.from_auction(auction.id)

    auction
    |> Command.start_auction
    |> AuctionStore.process_command

    assert AuctionStore.get_current_state(auction).status == :open

    :timer.sleep(1_000)

    expected_state = auction.id
    |> AuctionState.from_auction
    |> Map.merge(%{status: :decision, auction_id: auction.id})
    actual_state = AuctionStore.get_current_state(auction)

    assert expected_state == actual_state
  end

  test "auction decision period expiring", %{auction: auction} do
    auction
    |> Command.start_auction
    |> AuctionStore.process_command

    auction
    |> Command.end_auction
    |> AuctionStore.process_command

    auction
    |> Command.end_auction_decision_period
    |> AuctionStore.process_command

    expected_state = auction.id
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

    test "non-lowest bid is not added and duration does not extend", %{auction: auction, bid: bid} do
      :timer.sleep(1_100)
      Auctions.place_bid(auction, %{"amount" => bid.amount + 1}, bid.supplier_id)
      auction_payload = AuctionPayload.get_auction_payload!(auction, auction.buyer_id)

      assert Enum.all?(auction_payload.state.lowest_bids, fn(lowest_bid) ->
        lowest_bid.id in [bid.id]
      end)
      assert auction_payload.time_remaining < 3 * 60_000 - 1_000
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
  end

  describe "winning bid" do
    setup %{auction: auction, supplier_company: supplier_company, supplier2_company: supplier2_company} do
      Auctions.start_auction(auction)
      bid = Auctions.place_bid(auction, %{"amount" => 1.25}, supplier_company.id)
      bid2 = Auctions.place_bid(auction, %{"amount" => 1.25}, supplier2_company.id)

      auction
      |> Command.end_auction
      |> AuctionStore.process_command

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
