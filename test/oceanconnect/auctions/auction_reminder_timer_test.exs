defmodule Oceanconnect.Auctions.AuctionReminderTimerTest do
  use Oceanconnect.DataCase
  alias Oceanconnect.Auctions.{AuctionSupervisor, AuctionReminderTimer, AuctionEventStorage}

  setup do
    {:ok, test_start_time} = DateTime.to_unix(DateTime.utc_now(), :millisecond) + 60_500
    |> DateTime.from_unix(:millisecond)
    auction = insert(:auction, scheduled_start: test_start_time)

    {:ok, _pid} = start_supervised({AuctionSupervisor, {auction, %{exclude_children: []}}})
    {:ok, %{auction: auction}}
  end

  test "start auction_reminder_timer for auction", %{auction: auction} do
    :timer.sleep(500)
    assert Enum.any?(AuctionEventStorage.events_by_auction(auction.id), fn(event) -> event.type == :upcoming_auction_notified end)
  end
end
