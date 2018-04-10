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

  describe "auction event store" do
    test "starting an auction adds an auction_started event to the event store", %{auction: auction = %Auction{id: auction_id}} do
      assert :ok = Phoenix.PubSub.subscribe(:auction_pubsub, "auction:#{auction_id}")
      Auctions.start_auction(auction)
      assert_received %AuctionEvent{type: :auction_started, auction_id: ^auction_id}
      assert [%AuctionEvent{type: :auction_started, auction_id: ^auction_id, data: _}] = AuctionEventStore.event_list(auction)
    end

    test "ending an auction add an auction_ended event to the event store", %{auction: auction = %Auction{id: auction_id}} do
      assert :ok = Phoenix.PubSub.subscribe(:auction_pubsub, "auction:#{auction_id}")

      Auctions.start_auction(auction)
      Auctions.end_auction(auction)

      # We're sleeping so that the decision_duration timer doesn't expire
      # TODO: figure out how to avoid this
      :timer.sleep(1000)

      assert_received %AuctionEvent{type: :auction_ended, auction_id: ^auction_id}
      assert [%AuctionEvent{type: :auction_ended, auction_id: ^auction_id, data: _},
              %AuctionEvent{type: :auction_started, auction_id: ^auction_id, data: _}] = AuctionEventStore.event_list(auction)
    end
  end
end
