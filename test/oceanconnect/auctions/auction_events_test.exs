defmodule Oceanconnect.Auctions.AuctionEventsTest do
  use Oceanconnect.DataCase
  alias Oceanconnect.Auctions
  alias Oceanconnect.Auctions.{Auction, AuctionEvent, AuctionEventStore}
  # alias Oceanconnect.Auctions.AuctionStore.{AuctionState}

  setup do
    supplier_company = insert(:company)
    supplier2_company = insert(:company)
    auction = insert(:auction, duration: 1_000, decision_duration: 1_000, suppliers: [supplier_company, supplier2_company])

    Oceanconnect.Auctions.AuctionsSupervisor.start_child(auction.id)

    {:ok, %{auction: auction, supplier_company: supplier_company, supplier2_company: supplier2_company}}
  end

  test "subscribing to and receiving auction events", %{auction: auction} do
    assert :ok = Phoenix.PubSub.subscribe(:auction_pubsub, "auction:#{auction.id}")

    Phoenix.PubSub.broadcast(:auction_pubsub, "auction:#{auction.id}", {:auction_started, [created_at: DateTime.utc_now()]})
    assert_received {:auction_started, [created_at: _]}
  end

  test "starting an auction emits a auction_started event", %{auction: auction = %Auction{id: auction_id}} do
    assert :ok = Phoenix.PubSub.subscribe(:auction_pubsub, "auction:#{auction_id}")
    Auctions.start_auction(auction)
    assert_received %AuctionEvent{type: :auction_started, auction_id: ^auction_id}
  end

  test "events for an auction are persisted", %{auction: auction = %Auction{id: auction_id}} do
    assert :ok = Phoenix.PubSub.subscribe(:auction_pubsub, "auction:#{auction_id}")
    Auctions.start_auction(auction)
    assert [%AuctionEvent{type: :auction_started, auction_id: ^auction_id, data: _}] = AuctionEventStore.event_list(auction)
  end

end
