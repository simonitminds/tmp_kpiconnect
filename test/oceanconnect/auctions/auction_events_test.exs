defmodule Oceanconnect.Auctions.AuctionEventsTest do
  use Oceanconnect.DataCase
  alias Oceanconnect.Auctions
  alias Oceanconnect.Auctions.{Auction, AuctionEvent, AuctionEventStore, AuctionSupervisor}

  setup do
    supplier_company = insert(:company)
    supplier2_company = insert(:company)
    buyer_company = insert(:company, is_supplier: false)

    auction =
      insert(
        :auction,
        duration: 1_000,
        decision_duration: 1_000,
        suppliers: [supplier_company, supplier2_company],
        buyer: buyer_company
      )
      |> Auctions.fully_loaded()

    {:ok, _pid} =
      start_supervised(
        {AuctionSupervisor,
         {auction,
          %{
            exclude_children: [
              :auction_reminder_timer,
              :auction_event_handler,
              :auction_scheduler
            ]
          }}}
      )

    {:ok, %{auction: auction, supplier: supplier_company}}
  end

  test "subscribing to and receiving auction events", %{auction: %{id: auction_id}} do
    assert :ok = Phoenix.PubSub.subscribe(:auction_pubsub, "auction:#{auction_id}")

    AuctionEvent.emit(
      %AuctionEvent{type: :auction_started, auction_id: auction_id, data: %{}},
      true
    )

    assert_received %AuctionEvent{type: :auction_started, auction_id: ^auction_id, data: %{}}
  end

  describe "auction event store" do
    test "creating an auction adds an auction_created event to the event store", %{
      auction: auction
    } do
      auction_attrs =
        auction
        |> Map.take([
          :scheduled_start,
          :eta,
          :fuel_id,
          :port_id,
          :vessel_id,
          :suppliers,
          :buyer_id
        ])

      {:ok, new_auction} = Auctions.create_auction(auction_attrs)
      :timer.sleep(500)

      assert Enum.any?(AuctionEventStore.event_list(new_auction.id), fn event ->
               event.type == :auction_created && event.auction_id == new_auction.id
             end)
    end

    test "update_auction/2 adds an auction_updated event to the event store", %{
      auction: auction = %Auction{id: auction_id}
    } do
      assert :ok = Phoenix.PubSub.subscribe(:auction_pubsub, "auction:#{auction_id}")
      Auctions.update_auction(auction, %{anonymous_bidding: true}, nil)
      :timer.sleep(500)
      assert_received %AuctionEvent{type: :auction_updated, auction_id: ^auction_id}

      assert [%AuctionEvent{type: :auction_updated, auction_id: ^auction_id, data: _}] =
               AuctionEventStore.event_list(auction.id)
    end

    test "update_auction!/3 adds an auction_updated event to the event store and cache is updated",
         %{auction: auction = %Auction{id: auction_id}} do
      assert :ok = Phoenix.PubSub.subscribe(:auction_pubsub, "auction:#{auction_id}")
      updated_auction = Auctions.update_auction!(auction, %{anonymous_bidding: true}, nil)
      :timer.sleep(500)
      assert_received %AuctionEvent{type: :auction_updated, auction_id: ^auction_id}

      assert [%AuctionEvent{type: :auction_updated, auction_id: ^auction_id, data: _}] =
               AuctionEventStore.event_list(auction.id)

      cached_auction = Auctions.AuctionCache.read(auction_id)
      assert cached_auction.anonymous_bidding == updated_auction.anonymous_bidding
    end

    test "starting an auction adds an auction_started event to the event store", %{
      auction: auction = %Auction{id: auction_id}
    } do
      assert :ok = Phoenix.PubSub.subscribe(:auction_pubsub, "auction:#{auction_id}")
      Auctions.start_auction(auction)
      :timer.sleep(500)
      assert_received %AuctionEvent{type: :auction_started, auction_id: ^auction_id}

      assert [
               %AuctionEvent{type: :auction_started, auction_id: ^auction_id, data: _}
             ] = AuctionEventStore.event_list(auction.id)
    end

    test "placing a bid adds a bid_placed event to the event store", %{
      auction: auction = %Auction{id: auction_id}
    } do
      assert :ok = Phoenix.PubSub.subscribe(:auction_pubsub, "auction:#{auction_id}")

      Auctions.start_auction(auction)
      Auctions.place_bid(auction, %{"amount" => 1.25}, hd(auction.suppliers).id)

      :timer.sleep(500)
      assert_received %AuctionEvent{type: :bid_placed, auction_id: ^auction_id}

      assert [
               %AuctionEvent{type: :duration_extended, auction_id: ^auction_id, data: _},
               %AuctionEvent{type: :bid_placed, auction_id: ^auction_id, data: _},
               %AuctionEvent{type: :auction_started, auction_id: ^auction_id, data: _}
             ] = AuctionEventStore.event_list(auction_id)
    end

    test "placing a traded bid adds a traded_bid_place event to the event store", %{
      auction: auction = %Auction{id: auction_id}
    } do
      assert :ok = Phoenix.PubSub.subscribe(:auction_pubsub, "auction:#{auction_id}")

      Auctions.start_auction(auction)

      Auctions.place_bid(
        auction,
        %{"amount" => 1.25, "is_traded_bid" => true},
        hd(auction.suppliers).id
      )

      :timer.sleep(500)
      assert_received %AuctionEvent{type: :traded_bid_placed, auction_id: ^auction_id}

      assert [
               %AuctionEvent{type: :duration_extended, auction_id: ^auction_id, data: _},
               %AuctionEvent{type: :traded_bid_placed, auction_id: ^auction_id, data: _},
               %AuctionEvent{type: :auction_started, auction_id: ^auction_id, data: _}
             ] = AuctionEventStore.event_list(auction_id)
    end

    test "ending an auction adds an auction_ended event to the event store", %{
      auction: auction = %Auction{id: auction_id}
    } do
      assert :ok = Phoenix.PubSub.subscribe(:auction_pubsub, "auction:#{auction_id}")
      Auctions.start_auction(auction)
      Auctions.end_auction(auction)
      :timer.sleep(500)

      assert_received %AuctionEvent{type: :auction_ended, auction_id: ^auction_id}

      assert [
               %AuctionEvent{type: :auction_ended, auction_id: ^auction_id, data: _},
               %AuctionEvent{type: :auction_started, auction_id: ^auction_id, data: _}
             ] = AuctionEventStore.event_list(auction.id)
    end

    test "selecting the winning bid", %{auction: auction = %Auction{id: auction_id}} do
      assert :ok = Phoenix.PubSub.subscribe(:auction_pubsub, "auction:#{auction_id}")

      Auctions.start_auction(auction)
      bid = Auctions.place_bid(auction, %{"amount" => 1.25}, hd(auction.suppliers).id)
      Auctions.end_auction(auction)
      Auctions.select_winning_bid(bid, "Winner Winner Chicken Dinner.")
      :timer.sleep(500)

      assert_received %AuctionEvent{type: :winning_bid_selected, auction_id: ^auction_id}

      assert [
               %AuctionEvent{type: :auction_closed, auction_id: ^auction_id, data: _},
               %AuctionEvent{type: :winning_bid_selected, auction_id: ^auction_id, data: _},
               %AuctionEvent{type: :auction_ended, auction_id: ^auction_id, data: _},
               %AuctionEvent{type: :duration_extended, auction_id: ^auction_id, data: _},
               %AuctionEvent{type: :bid_placed, auction_id: ^auction_id, data: _},
               %AuctionEvent{type: :auction_started, auction_id: ^auction_id, data: _}
             ] = AuctionEventStore.event_list(auction.id)
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
               %AuctionEvent{type: :duration_extended, auction_id: ^auction_id, data: _},
               %AuctionEvent{type: :bid_placed, auction_id: ^auction_id, data: _},
               %AuctionEvent{type: :duration_extended, auction_id: ^auction_id, data: _},
               %AuctionEvent{type: :bid_placed, auction_id: ^auction_id, data: _},
               %AuctionEvent{type: :auction_started, auction_id: ^auction_id, data: _}
             ] = AuctionEventStore.event_list(auction.id)
    end

    test "submitting a barge", %{auction: auction = %Auction{id: auction_id}, supplier: supplier} do
      assert :ok = Phoenix.PubSub.subscribe(:auction_pubsub, "auction:#{auction_id}")
      barge = insert(:barge, companies: [supplier])

      Auctions.submit_barge(auction, barge, supplier.id)
      :timer.sleep(500)

      assert_received %AuctionEvent{type: :barge_submitted, auction_id: ^auction_id}

      assert [
               %AuctionEvent{type: :barge_submitted, auction_id: ^auction_id}
             ] = AuctionEventStore.event_list(auction.id)
    end

    test "unsubmitting a barge", %{
      auction: auction = %Auction{id: auction_id},
      supplier: supplier
    } do
      assert :ok = Phoenix.PubSub.subscribe(:auction_pubsub, "auction:#{auction_id}")
      barge = insert(:barge, companies: [supplier])

      Auctions.submit_barge(auction, barge, supplier.id)
      Auctions.unsubmit_barge(auction, barge, supplier.id)
      :timer.sleep(500)

      assert_received %AuctionEvent{type: :barge_unsubmitted, auction_id: ^auction_id}

      assert [
               %AuctionEvent{type: :barge_unsubmitted, auction_id: ^auction_id},
               %AuctionEvent{type: :barge_submitted, auction_id: ^auction_id}
             ] = AuctionEventStore.event_list(auction.id)
    end

    test "approving a barge", %{auction: auction = %Auction{id: auction_id}, supplier: supplier} do
      assert :ok = Phoenix.PubSub.subscribe(:auction_pubsub, "auction:#{auction_id}")
      barge = insert(:barge, companies: [supplier])

      Auctions.submit_barge(auction, barge, supplier.id)
      Auctions.approve_barge(auction, barge, supplier.id)
      :timer.sleep(500)

      assert_received %AuctionEvent{type: :barge_approved, auction_id: ^auction_id}

      assert [
               %AuctionEvent{type: :barge_approved, auction_id: ^auction_id},
               %AuctionEvent{type: :barge_submitted, auction_id: ^auction_id}
             ] = AuctionEventStore.event_list(auction.id)
    end

    test "rejecting a barge", %{auction: auction = %Auction{id: auction_id}, supplier: supplier} do
      assert :ok = Phoenix.PubSub.subscribe(:auction_pubsub, "auction:#{auction_id}")
      barge = insert(:barge, companies: [supplier])

      Auctions.submit_barge(auction, barge, supplier.id)
      Auctions.reject_barge(auction, barge, supplier.id)
      :timer.sleep(500)

      assert_received %AuctionEvent{type: :barge_rejected, auction_id: ^auction_id}

      assert [
               %AuctionEvent{type: :barge_rejected, auction_id: ^auction_id},
               %AuctionEvent{type: :barge_submitted, auction_id: ^auction_id}
             ] = AuctionEventStore.event_list(auction.id)
    end
  end
end
