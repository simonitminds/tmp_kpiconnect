defmodule Oceanconnect.Auctions.AuctionSchedulerTest do
  use Oceanconnect.DataCase
  alias Oceanconnect.Auctions
  alias Oceanconnect.Auctions.{Auction, AuctionEvent, AuctionSupervisor}

  setup do
    start = DateTime.utc_now() |> DateTime.to_naive |> NaiveDateTime.add(3) |> DateTime.from_naive!("Etc/UTC")
    auction = insert(:auction, scheduled_start: start)
    {:ok, _pid} = start_supervised({AuctionSupervisor, {auction, %{exclude_children: [:auction_event_handler]}}})
    {:ok, %{auction: auction}}
  end

  test "start auction based on scheduler", %{auction: auction = %Auction{id: auction_id, scheduled_start: start}} do
    assert :ok = Phoenix.PubSub.subscribe(:auction_pubsub, "auction:#{auction_id}")
    assert Auctions.get_auction_state!(auction).status == :pending
    receive do
      %AuctionEvent{type: :auction_started, auction_id: ^auction_id, data: %{}, time_entered: start_time} ->
        gt_start = start |> DateTime.to_naive |> NaiveDateTime.add(1) |> DateTime.from_naive!("Etc/UTC")
        assert DateTime.compare(gt_start, start_time) == :gt
    after
      5000 ->
        assert false, "Expected message received nothing."
    end
  end

  test "update start time", %{auction: auction = %Auction{id: auction_id}} do
    assert :ok = Phoenix.PubSub.subscribe(:auction_pubsub, "auction:#{auction_id}")
    now = DateTime.utc_now()
    Auctions.update_auction(auction, %{scheduled_start: now}, nil)
    receive do
      %AuctionEvent{type: :auction_started, auction_id: ^auction_id, data: %{}, time_entered: start_time} ->
        gt_start = now |> DateTime.to_naive |> NaiveDateTime.add(1) |> DateTime.from_naive!("Etc/UTC")
        assert DateTime.compare(gt_start, start_time) == :gt
    after
      5000 ->
        assert false, "Expected message received nothing."
    end
  end
end
