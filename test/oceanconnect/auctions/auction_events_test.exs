defmodule Oceanconnect.Auctions.AuctionEventsTest do
  use Oceanconnect.DataCase
  alias Oceanconnect.Auctions
  alias Oceanconnect.Auctions.{Auction, AuctionEvent, AuctionEventStore, AuctionSupervisor}

  setup do
    supplier_company = insert(:company)
    supplier2_company = insert(:company)
    buyer_company = insert(:company, is_supplier: false)
    fuel = insert(:fuel)
    fuel_id = "#{fuel.id}"

    auction =
      insert(
        :auction,
        duration: 1_000,
        decision_duration: 1_000,
        suppliers: [supplier_company, supplier2_company],
        auction_vessel_fuels: [build(:vessel_fuel, fuel: fuel)],
        buyer: buyer_company,
        is_traded_bid_allowed: true
      )
      |> Auctions.fully_loaded()

    {:ok, _pid} =
      start_supervised(
        {AuctionSupervisor,
         {auction,
          %{
            exclude_children: [
              :auction_reminder_timer,
              :auction_event_handler
            ]
          }}}
      )

    {:ok, %{auction: auction, fuel: fuel, fuel_id: fuel_id, supplier: supplier_company}}
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
          :auction_vessel_fuels,
          :suppliers,
          :buyer_id
        ])

      {:ok, new_auction} = Auctions.create_auction(auction_attrs)
      :timer.sleep(200)

      assert Enum.any?(AuctionEventStore.event_list(new_auction.id), fn event ->
               event.type == :auction_created && event.auction_id == new_auction.id
             end)
    end

    test "update_auction/2 adds an auction_updated event to the event store", %{
      auction: auction = %Auction{id: auction_id}
    } do
      assert :ok = Phoenix.PubSub.subscribe(:auction_pubsub, "auction:#{auction_id}")
      Auctions.update_auction(auction, %{anonymous_bidding: true}, nil)
      :timer.sleep(200)
      assert_received %AuctionEvent{type: :auction_updated, auction_id: ^auction_id}

      assert [%AuctionEvent{type: :auction_updated, auction_id: ^auction_id, data: _}] =
               AuctionEventStore.event_list(auction.id)
    end

    test "update_auction!/3 adds an auction_updated event to the event store and cache is updated",
         %{auction: auction = %Auction{id: auction_id}} do
      assert :ok = Phoenix.PubSub.subscribe(:auction_pubsub, "auction:#{auction_id}")
      updated_auction = Auctions.update_auction!(auction, %{anonymous_bidding: true}, nil)
      :timer.sleep(200)
      assert_received %AuctionEvent{type: :auction_updated, auction_id: ^auction_id}

      assert [%AuctionEvent{type: :auction_updated, auction_id: ^auction_id, data: _}] =
               AuctionEventStore.event_list(auction.id)

      cached_auction = Auctions.AuctionCache.read(auction_id)
      assert cached_auction.anonymous_bidding == updated_auction.anonymous_bidding
    end

    test "update_auction/2 with a new start time adds an auction_rescheduled event to the event store",
         %{
           auction: auction = %Auction{id: auction_id}
         } do
      new_start_time =
        auction.scheduled_start
        |> DateTime.to_unix()
        |> Kernel.+(1_000_000)
        |> DateTime.from_unix!()

      assert :ok = Phoenix.PubSub.subscribe(:auction_pubsub, "auction:#{auction_id}")
      Auctions.update_auction(auction, %{scheduled_start: new_start_time}, nil)
      :timer.sleep(200)
      assert_received %AuctionEvent{type: :auction_updated, auction_id: ^auction_id}
      assert_received %AuctionEvent{type: :auction_rescheduled, auction_id: ^auction_id}
    end

    test "starting an auction adds an auction_started event to the event store", %{
      auction: auction = %Auction{id: auction_id}
    } do
      assert :ok = Phoenix.PubSub.subscribe(:auction_pubsub, "auction:#{auction_id}")
      Auctions.start_auction(auction)
      :timer.sleep(400)
      assert_received %AuctionEvent{type: :auction_started, auction_id: ^auction_id}

      assert [
               %AuctionEvent{type: :auction_started, auction_id: ^auction_id, data: _}
             ] = AuctionEventStore.event_list(auction.id)
    end

    test "placing a bid adds a bid_placed event to the event store", %{
      auction: auction = %Auction{id: auction_id},
      fuel_id: fuel_id
    } do
      assert :ok = Phoenix.PubSub.subscribe(:auction_pubsub, "auction:#{auction_id}")
      Auctions.start_auction(auction)

      create_bid(1.25, nil, hd(auction.suppliers).id, fuel_id, auction)
      |> Auctions.place_bid()

      :timer.sleep(200)
      assert_received %AuctionEvent{type: :bid_placed, auction_id: ^auction_id}

      assert [
               %AuctionEvent{type: :duration_extended, auction_id: ^auction_id, data: _},
               %AuctionEvent{type: :bid_placed, auction_id: ^auction_id, data: _},
               %AuctionEvent{type: :auction_started, auction_id: ^auction_id, data: _}
             ] = AuctionEventStore.event_list(auction_id)
    end

    test "placing a traded bid adds a bid_placed event to the event store", %{
      auction: auction = %Auction{id: auction_id},
      fuel_id: fuel_id
    } do
      assert :ok = Phoenix.PubSub.subscribe(:auction_pubsub, "auction:#{auction_id}")
      Auctions.start_auction(auction)

      create_bid(1.25, nil, hd(auction.suppliers).id, fuel_id, auction, true)
      |> Auctions.place_bid()

      :timer.sleep(200)
      assert_received %AuctionEvent{type: :bid_placed, auction_id: ^auction_id}

      assert [
               %AuctionEvent{type: :duration_extended, auction_id: ^auction_id, data: _},
               %AuctionEvent{
                 type: :bid_placed,
                 auction_id: ^auction_id,
                 data: %{bid: %{is_traded_bid: true}}
               },
               %AuctionEvent{type: :auction_started, auction_id: ^auction_id, data: _}
             ] = AuctionEventStore.event_list(auction_id)
    end

    test "revoking a supplier's bids adds a bids_revoked event to the event store", %{
      auction: auction = %Auction{id: auction_id},
      fuel_id: fuel_id
    } do
      supplier_id = hd(auction.suppliers).id

      assert :ok = Phoenix.PubSub.subscribe(:auction_pubsub, "auction:#{auction_id}")
      Auctions.start_auction(auction)

      create_bid(1.25, nil, supplier_id, fuel_id, auction)
      |> Auctions.place_bid()

      :timer.sleep(100)
      Auctions.revoke_supplier_bids_for_product(auction, fuel_id, supplier_id)

      :timer.sleep(200)
      assert_received %AuctionEvent{type: :bid_placed, auction_id: ^auction_id}

      assert [
               %AuctionEvent{type: :bids_revoked, auction_id: ^auction_id, data: _},
               %AuctionEvent{type: :duration_extended, auction_id: ^auction_id, data: _},
               %AuctionEvent{type: :bid_placed, auction_id: ^auction_id, data: _},
               %AuctionEvent{type: :auction_started, auction_id: ^auction_id, data: _}
             ] = AuctionEventStore.event_list(auction_id)
    end

    test "ending an auction adds an auction_ended event to the event store", %{
      auction: auction = %Auction{id: auction_id}
    } do
      assert :ok = Phoenix.PubSub.subscribe(:auction_pubsub, "auction:#{auction_id}")
      Auctions.start_auction(auction)
      Auctions.end_auction(auction)
      :timer.sleep(200)

      assert_received %AuctionEvent{type: :auction_ended, auction_id: ^auction_id}

      assert [
               %AuctionEvent{type: :auction_ended, auction_id: ^auction_id, data: _},
               %AuctionEvent{type: :auction_started, auction_id: ^auction_id, data: _}
             ] = AuctionEventStore.event_list(auction.id)
    end

    test "selecting the winning solution", %{
      auction: auction = %Auction{id: auction_id},
      fuel_id: fuel_id
    } do
      assert :ok = Phoenix.PubSub.subscribe(:auction_pubsub, "auction:#{auction_id}")

      Auctions.start_auction(auction)

      bid =
        create_bid(1.25, nil, hd(auction.suppliers).id, fuel_id, auction, true)
        |> Auctions.place_bid()

      Auctions.end_auction(auction)
      state = Auctions.get_auction_state!(auction)

      Auctions.select_winning_solution(
        [bid],
        state.product_bids,
        auction,
        "Winner Winner Chicken Dinner.",
        "Agent 9"
      )

      :timer.sleep(200)

      assert_received %AuctionEvent{type: :winning_solution_selected, auction_id: ^auction_id}

      assert [
               %AuctionEvent{type: :auction_closed, auction_id: ^auction_id, data: _},
               %AuctionEvent{type: :winning_solution_selected, auction_id: ^auction_id, data: _},
               %AuctionEvent{type: :auction_ended, auction_id: ^auction_id, data: _},
               %AuctionEvent{type: :duration_extended, auction_id: ^auction_id, data: _},
               %AuctionEvent{type: :bid_placed, auction_id: ^auction_id, data: _},
               %AuctionEvent{type: :auction_started, auction_id: ^auction_id, data: _}
             ] = AuctionEventStore.event_list(auction.id)
    end

    test "ensure events are in proper order", %{
      auction: auction = %Auction{id: auction_id},
      fuel_id: fuel_id
    } do
      assert :ok = Phoenix.PubSub.subscribe(:auction_pubsub, "auction:#{auction_id}")

      Auctions.start_auction(auction)

      create_bid(1.25, nil, hd(auction.suppliers).id, fuel_id, auction)
      |> Auctions.place_bid()

      create_bid(1.50, nil, hd(auction.suppliers).id, fuel_id, auction)
      |> Auctions.place_bid()

      Auctions.end_auction(auction)
      :timer.sleep(200)

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
      :timer.sleep(200)

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
      :timer.sleep(200)

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
      :timer.sleep(200)

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
      :timer.sleep(200)

      assert_received %AuctionEvent{type: :barge_rejected, auction_id: ^auction_id}

      assert [
               %AuctionEvent{type: :barge_rejected, auction_id: ^auction_id},
               %AuctionEvent{type: :barge_submitted, auction_id: ^auction_id}
             ] = AuctionEventStore.event_list(auction.id)
    end
  end
end
