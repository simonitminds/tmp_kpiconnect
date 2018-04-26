defmodule Oceanconnect.Auctions.AuctionEventStorageTest do
  use Oceanconnect.DataCase
  alias Oceanconnect.Auctions.{AuctionEvent, AuctionEventStorage}

  test "persist/1 persists to storage and returns hydrated event" do
    event = %AuctionEvent{type: "test"}
    event_storage = %AuctionEventStorage{event: event}
    {:ok, persisted_storage} = AuctionEventStorage.persist(event_storage)
    assert hd(Repo.all(AuctionEventStorage)).id == persisted_storage.id
    assert persisted_storage.event == event
  end

  test "events_by_auction/1 returns events in reverse chronological order" do
    auction = insert(:auction)
    AuctionEventStorage.persist(%AuctionEventStorage{auction_id: auction.id, event: %AuctionEvent{type: "1"}})
    AuctionEventStorage.persist(%AuctionEventStorage{auction_id: auction.id, event: %AuctionEvent{type: "2"}})
    AuctionEventStorage.persist(%AuctionEventStorage{auction_id: auction.id, event: %AuctionEvent{type: "3"}})
    event_list = AuctionEventStorage.events_by_auction(auction.id)
    assert ["3", "2", "1"] == Enum.map(event_list, &(&1.type))
  end
end
