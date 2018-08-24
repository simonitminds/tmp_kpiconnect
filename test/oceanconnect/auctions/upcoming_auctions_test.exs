defmodule Oceanconnect.Auctions.UpcomingAuctionsTest do
  use Oceanconnect.DataCase
  use Supervisor
  alias Oceanconnect.Auctions.{AuctionEventStorage, UpcomingAuctions}

  setup do
    {:ok, scheduled_start} = DateTime.to_unix(DateTime.utc_now(), :millisecond) + 45_000
    |> DateTime.from_unix(:millisecond)
    auction = insert(:auction, scheduled_start: scheduled_start)
    polling_frequency = 15_000
    time_frame = 60_000
    {:ok, _pid} = Supervisor.start_link([
      {UpcomingAuctions, [polling_frequency, time_frame]}
    ])
    {:ok, %{auction: auction}}
  end

  describe "upcoming auctions task" do
    test "an upcoming auction adds an upcoming_auction_notified event to the even store", %{auction: auction} do
      assert Enum.any?(AuctionEventStorage.events_by_auction(auction.id), fn(event) -> event.type == :upcoming_auction_notified end)
    end
  end
end
