defmodule Oceanconnect.Auctions.AuctionSchedulerTest do
  use Oceanconnect.DataCase
  alias Oceanconnect.Auctions
  alias Oceanconnect.Auctions.{Auction, AuctionEvent, AuctionSupervisor}

  setup do
    start =
      DateTime.utc_now()
      |> DateTime.to_naive()
      |> NaiveDateTime.add(3)
      |> DateTime.from_naive!("Etc/UTC")

    auction = insert(:auction, scheduled_start: start) |> Auctions.fully_loaded()

    {:ok, _pid} =
      start_supervised(
        {AuctionSupervisor,
         {auction, %{exclude_children: [:auction_reminder_timer, :auction_event_handler]}}}
      )

    {:ok, %{auction: auction}}
  end

  test "start auction based on scheduler", %{
    auction: auction = %Auction{id: auction_id, scheduled_start: start}
  } do
    assert :ok = Phoenix.PubSub.subscribe(:auction_pubsub, "auction:#{auction_id}")
    assert Auctions.get_auction_state!(auction).status == :pending

    receive do
      {%AuctionEvent{
        type: :auction_started,
        auction_id: ^auction_id,
        data: %{},
        time_entered: start_time
      }, _state} ->
        gt_start =
          start |> DateTime.to_naive() |> NaiveDateTime.add(1) |> DateTime.from_naive!("Etc/UTC")

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
      {%AuctionEvent{
        type: :auction_started,
        auction_id: ^auction_id,
        data: %{},
        time_entered: start_time
      }, _state} ->
        gt_start =
          now |> DateTime.to_naive() |> NaiveDateTime.add(1) |> DateTime.from_naive!("Etc/UTC")

        assert DateTime.compare(gt_start, start_time) == :gt
    after
      5000 ->
        assert false, "Expected message received nothing."
    end
  end

  test "draft auctions that become scheduled auctions, start at their scheduled time" do
    draft_auction = insert(:draft_auction)
    auction_id = draft_auction.id

    AuctionSupervisor.start_link({draft_auction, %{exclude_children: []}})

    assert :ok = Phoenix.PubSub.subscribe(:auction_pubsub, "auction:#{auction_id}")
    now = DateTime.utc_now()

    assert %{status: :draft} = Auctions.get_auction_state!(draft_auction)

    Auctions.update_auction(draft_auction, %{scheduled_start: now}, nil)

    assert %{status: :pending} = Auctions.get_auction_state!(draft_auction)

    {:ok, scheduler_pid} = Oceanconnect.Auctions.AuctionScheduler.find_pid(auction_id)

    receive do
       {%AuctionEvent{
        type: :auction_updated,
        auction_id: ^auction_id,
        time_entered: start_time
      }, _state} ->
        gt_start =
          now |> DateTime.to_naive() |> NaiveDateTime.add(1) |> DateTime.from_naive!("Etc/UTC")

        :timer.sleep(500)

        assert DateTime.compare(gt_start, start_time) == :gt
        assert DateTime.compare(:sys.get_state(scheduler_pid).scheduled_start, now) == :eq
    after
      5000 ->
        assert false, "Expected message received nothing."
    end

    :timer.sleep(500)
    assert %{status: :open} = Auctions.get_auction_state!(draft_auction)
  end
end
