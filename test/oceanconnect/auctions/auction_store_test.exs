defmodule Oceanconnect.Auctions.AuctionStoreTest do
  use Oceanconnect.DataCase
  alias Oceanconnect.Auctions.{AuctionBidList, AuctionPayload, AuctionStore, Command}
  alias Oceanconnect.Auctions.AuctionStore.{AuctionState}

  setup do
    supplier_company = insert(:company)
    supplier2_company = insert(:company)
    auction = insert(:auction, duration: 1_000, decision_duration: 1_000,
                      suppliers: [supplier_company, supplier2_company])
    Oceanconnect.Auctions.AuctionsSupervisor.start_child(auction)
    {:ok, %{auction: auction, supplier_company: supplier_company, supplier2_company: supplier2_company}}
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
    assert AuctionStore.get_current_state(auction) == AuctionState.from_auction(auction)

    auction
    |> Command.start_auction
    |> AuctionStore.process_command

    assert AuctionStore.get_current_state(auction).status == :open

    :timer.sleep(1_000)

    expected_state = auction
    |> AuctionState.from_auction
    |> Map.merge(%{status: :decision, auction_id: auction.id})
    actual_state = AuctionStore.get_current_state(auction)

    assert expected_state == actual_state
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

    expected_state = auction
    |> AuctionState.from_auction
    |> Map.merge(%{status: :closed, auction_id: auction.id})
    actual_state = AuctionStore.get_current_state(auction)

    assert expected_state == actual_state
  end

  describe "winning bid list" do
    setup %{auction: auction, supplier_company: supplier_company} do
      bid = %{"amount" => "1.25"}
      |> Map.put("supplier_id", supplier_company.id)
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
      auction_payload = AuctionPayload.get_auction_payload!(auction, auction.buyer_id)

      assert Enum.all?(auction_payload.state.winning_bids, fn(winning_bid) ->
        winning_bid.id in [bid.id]
      end)
      assert auction_payload.time_remaining > 2 * 60_000
    end

    test "matching bid is added and extends duration", %{auction: auction, bid: bid} do
      new_bid = bid
      |> Map.merge(%{id: UUID.uuid4(:hex), time_entered: DateTime.utc_now()})

      new_bid
      |> Command.process_new_bid
      |> AuctionStore.process_command

      auction_payload = AuctionPayload.get_auction_payload!(auction, auction.buyer_id)

      assert Enum.all?(auction_payload.state.winning_bids, fn(winning_bid) ->
        winning_bid.id in [bid.id, new_bid.id]
      end)
      assert auction_payload.time_remaining > 2 * 60_000
    end

    test "non-winning bid is not added and duration does not extend", %{auction: auction, bid: bid} do
      new_bid = bid
      |> Map.merge(%{id: UUID.uuid4(:hex), time_entered: DateTime.utc_now(), amount: "1.50"})

      new_bid
      |> Command.process_new_bid
      |> AuctionStore.process_command

      :timer.sleep(1_100)
      auction_payload = AuctionPayload.get_auction_payload!(auction, auction.buyer_id)

      assert Enum.all?(auction_payload.state.winning_bids, fn(winning_bid) ->
        winning_bid.id in [bid.id]
      end)
      assert auction_payload.time_remaining < 3 * 60_000 - 1_000
    end

    test "new winning bid is added and extends duration", %{auction: auction, bid: bid} do
      new_bid = bid
      |> Map.merge(%{id: UUID.uuid4(:hex), time_entered: DateTime.utc_now(), amount: "0.75"})

      new_bid
      |> Command.process_new_bid
      |> AuctionStore.process_command

      auction_payload = AuctionPayload.get_auction_payload!(auction, auction.buyer_id)

      assert Enum.all?(auction_payload.state.winning_bids, fn(winning_bid) ->
        winning_bid.id in [new_bid.id]
      end)
      assert auction_payload.time_remaining > 2 * 60_000
    end
  end
end
