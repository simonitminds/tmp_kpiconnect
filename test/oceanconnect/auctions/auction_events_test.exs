defmodule Oceanconnect.Auctions.AuctionEventsTest do
  use Oceanconnect.DataCase
  alias Oceanconnect.Auctions
  alias Oceanconnect.Auctions.{Auction, AuctionEvent, AuctionEventStore, AuctionSupervisor}

  setup do
    supplier_company = insert(:company)
    supplier2_company = insert(:company)
    auction = insert(:auction, duration: 1_000, decision_duration: 1_000, suppliers: [supplier_company, supplier2_company])

    {:ok, _pid} = start_supervised({AuctionSupervisor, auction})

    {:ok, %{auction: auction, supplier_company: supplier_company, supplier2_company: supplier2_company}}
  end

  test "subscribing to and receiving auction events", %{auction: %{id: auction_id}} do
    assert :ok = Phoenix.PubSub.subscribe(:auction_pubsub, "auction:#{auction_id}")

    AuctionEvent.emit(%AuctionEvent{type: :auction_started, auction_id: auction_id, data: %{}})
    assert_received %AuctionEvent{type: :auction_started, auction_id: ^auction_id, data: %{}}
  end

  describe "auction event store" do
    test "starting an auction adds an auction_started event to the event store", %{auction: auction = %Auction{id: auction_id}} do
      assert :ok = Phoenix.PubSub.subscribe(:auction_pubsub, "auction:#{auction_id}")
      Auctions.start_auction(auction)
      assert_received %AuctionEvent{type: :auction_started, auction_id: ^auction_id}
      assert [%AuctionEvent{type: :auction_started, auction_id: ^auction_id, data: _}] = AuctionEventStore.event_list(auction)
    end

    test "placing a bid adds a bid_placed event to the event store", %{auction: auction = %Auction{id: auction_id}} do
      assert :ok = Phoenix.PubSub.subscribe(:auction_pubsub, "auction:#{auction_id}")

      Auctions.start_auction(auction)
      Auctions.place_bid(auction, %{"amount" => 1.25}, hd(auction.suppliers).id)

      :timer.sleep(500)
      assert_received %AuctionEvent{type: :bid_placed, auction_id: ^auction_id}
      assert [
        %AuctionEvent{type: :duration_extended, auction_id: ^auction_id, data: _},
        %AuctionEvent{type: :duration_extended, auction_id: ^auction_id, data: _},
        %AuctionEvent{type: :bid_placed, auction_id: ^auction_id, data: _},
        %AuctionEvent{type: :auction_started, auction_id: ^auction_id, data: _}
      ] = AuctionEventStore.event_list(auction)
    end

    test "ending an auction adds an auction_ended event to the event store", %{auction: auction = %Auction{id: auction_id}} do
      assert :ok = Phoenix.PubSub.subscribe(:auction_pubsub, "auction:#{auction_id}")
      Auctions.start_auction(auction)
      Auctions.end_auction(auction)

      # We're sleeping so that the decision_duration timer doesn't expire
      # TODO: figure out how to avoid this
      :timer.sleep(500)

      assert_received %AuctionEvent{type: :auction_ended, auction_id: ^auction_id}
      assert [
        %AuctionEvent{type: :auction_ended, auction_id: ^auction_id, data: _},
        %AuctionEvent{type: :auction_started, auction_id: ^auction_id, data: _}
      ] = AuctionEventStore.event_list(auction)
    end

    test "selecting the winning bid", %{auction: auction = %Auction{id: auction_id}} do
      assert :ok = Phoenix.PubSub.subscribe(:auction_pubsub, "auction:#{auction_id}")

      Auctions.start_auction(auction)
      bid = Auctions.place_bid(auction, %{"amount" => 1.25}, hd(auction.suppliers).id)
      Auctions.end_auction(auction)
      Auctions.select_winning_bid(bid, "Winner Winner Chicken Dinner.")
      :timer.sleep(2000)

      assert_received %AuctionEvent{type: :winning_bid_selected, auction_id: ^auction_id}

      # TODO Remove the last duration_extended event this is a bug I believe
      assert [
        %AuctionEvent{type: :auction_closed, auction_id: ^auction_id, data: _},
        %AuctionEvent{type: :winning_bid_selected, auction_id: ^auction_id, data: _},
        %AuctionEvent{type: :auction_ended, auction_id: ^auction_id, data: _},
        %AuctionEvent{type: :duration_extended, auction_id: ^auction_id, data: _},
        %AuctionEvent{type: :duration_extended, auction_id: ^auction_id, data: _},
        %AuctionEvent{type: :bid_placed, auction_id: ^auction_id, data: _},
        %AuctionEvent{type: :auction_started, auction_id: ^auction_id, data: _}
      ] = AuctionEventStore.event_list(auction)
    end

    test "ensure events are in proper order", %{auction: auction = %Auction{id: auction_id}} do
      assert :ok = Phoenix.PubSub.subscribe(:auction_pubsub, "auction:#{auction_id}")

      Auctions.start_auction(auction)
      Auctions.place_bid(auction, %{"amount" => 1.25}, hd(auction.suppliers).id)
      Auctions.place_bid(auction, %{"amount" => 1.50}, hd(auction.suppliers).id)
      Auctions.end_auction(auction)
      :timer.sleep(500)

      assert [
        %AuctionEvent{type: :auction_ended, auction_id: ^auction_id, data: _},
        %AuctionEvent{type: :bid_placed, auction_id: ^auction_id, data: _},
        %AuctionEvent{type: :duration_extended, auction_id: ^auction_id, data: _},
        %AuctionEvent{type: :duration_extended, auction_id: ^auction_id, data: _},
        %AuctionEvent{type: :bid_placed, auction_id: ^auction_id, data: _},
        %AuctionEvent{type: :auction_started, auction_id: ^auction_id, data: _}
      ] = AuctionEventStore.event_list(auction)
    end
  end
end
