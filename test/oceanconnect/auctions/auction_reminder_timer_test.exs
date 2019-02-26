defmodule Oceanconnect.Auctions.AuctionReminderTimerTest do
  use Oceanconnect.DataCase

  alias Oceanconnect.Auctions
  alias Oceanconnect.Auctions.{AuctionSupervisor, AuctionEventStore, AuctionReminderTimer}

  setup do
    {:ok, test_start_time} =
      (DateTime.to_unix(DateTime.utc_now(), :millisecond) + 60_200)
      |> DateTime.from_unix(:millisecond)

    buyer_company = insert(:company, is_supplier: false)
    [insert(:user, company: buyer_company), insert(:user, company: buyer_company)]

    supplier_companies = [
      insert(:company, is_supplier: true),
      insert(:company, is_supplier: true)
    ]

    Enum.each(supplier_companies, fn supplier_company ->
      insert(:user, company: supplier_company)
    end)

    auction =
      insert(
        :auction,
        scheduled_start: test_start_time,
        suppliers: supplier_companies,
        buyer: buyer_company
      )
      |> Auctions.fully_loaded()

    Oceanconnect.FakeEventStorage.FakeEventStorageCache.start_link()

    {:ok, %{auction: auction}}
  end

  test "start auction_reminder_timer for auction", %{auction: auction} do
    {:ok, _pid} =
      start_supervised({AuctionSupervisor, {auction, %{exclude_children: [:auction_scheduler]}}})

    :timer.sleep(500)

    assert length(
             Enum.filter(AuctionEventStore.event_list(auction.id), fn event ->
               event.type == :upcoming_auction_notified
             end)
           ) == 1
  end

  test "shuts down gracefully for auctions with no scheduled_start" do
    auction = insert(:auction, scheduled_start: nil)

    {:ok, :shutdown} = AuctionReminderTimer.init(auction)
  end
end
