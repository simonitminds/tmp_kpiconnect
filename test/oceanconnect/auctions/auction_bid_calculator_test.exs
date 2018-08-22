defmodule Oceanconnect.Auctions.AuctionBidCalculatorTest do
  use Oceanconnect.DataCase
  alias Oceanconnect.Auctions.AuctionStore.AuctionState
  alias Oceanconnect.Auctions.AuctionBidCalculator
  alias Oceanconnect.Auctions.{AuctionBid, AuctionEvent}

  setup do
    supplier_company = insert(:company)
    supplier2_company = insert(:company)
    supplier3_company = insert(:company)

    auction =
      insert(
        :auction,
        duration: 1_000,
        decision_duration: 1_000,
        suppliers: [supplier_company, supplier2_company, supplier3_company]
      )

    {:ok,
     %{
       auction: auction,
       supplier1: supplier_company.id,
       supplier2: supplier2_company.id,
       supplier3: supplier3_company.id
     }}
  end

  describe "bidding" do
    test "with no previous bids", %{auction: auction, supplier1: supplier1} do
      auction_id = auction.id

      current_state = %AuctionState{
        auction_id: auction_id,
        status: :open,
        lowest_bids: [],
        minimum_bids: [],
        winning_bid: nil,
        bids: []
      }

      new_bid = %AuctionBid{
        amount: 2.00,
        supplier_id: supplier1,
        auction_id: auction_id,
        active: true
      }

      assert {%AuctionState{
                auction_id: ^auction_id,
                status: :open,
                winning_bid: nil,
                lowest_bids: [^new_bid],
                bids: [^new_bid],
                active_bids: [^new_bid],
                minimum_bids: [],
                inactive_bids: []
              }, _events} = AuctionBidCalculator.process(current_state, new_bid)
    end

    test "out bidding a previous bid", %{
      auction: auction,
      supplier1: supplier1,
      supplier2: supplier2
    } do
      auction_id = auction.id
      prev_bid = %AuctionBid{amount: 2.00, supplier_id: supplier1, auction_id: auction_id}

      current_state = %AuctionState{
        auction_id: auction_id,
        status: :open,
        lowest_bids: [prev_bid],
        minimum_bids: [],
        winning_bid: nil,
        active_bids: [prev_bid],
        bids: [prev_bid]
      }

      new_bid = %AuctionBid{amount: 1.75, supplier_id: supplier2, auction_id: auction_id}

      assert {%AuctionState{
                auction_id: ^auction_id,
                status: :open,
                winning_bid: nil,
                lowest_bids: [^new_bid, ^prev_bid],
                active_bids: [^new_bid, ^prev_bid],
                bids: [^new_bid, ^prev_bid],
                minimum_bids: []
              }, _events} = AuctionBidCalculator.process(current_state, new_bid)
    end

    test "entering a matching bid", %{
      auction: auction,
      supplier1: supplier1,
      supplier2: supplier2
    } do
      auction_id = auction.id

      prev_bid = %AuctionBid{
        amount: 2.00,
        supplier_id: supplier1,
        auction_id: auction_id,
        time_entered: DateTime.utc_now()
      }

      current_state = %AuctionState{
        auction_id: auction_id,
        status: :open,
        lowest_bids: [prev_bid],
        active_bids: [prev_bid],
        minimum_bids: [],
        winning_bid: nil,
        bids: [prev_bid]
      }

      new_bid = %AuctionBid{
        amount: 2.00,
        supplier_id: supplier2,
        auction_id: auction_id,
        time_entered: DateTime.utc_now()
      }

      assert {%AuctionState{
                auction_id: ^auction_id,
                status: :open,
                winning_bid: nil,
                lowest_bids: [^prev_bid, ^new_bid],
                bids: [^new_bid, ^prev_bid],
                minimum_bids: []
              }, _events} = AuctionBidCalculator.process(current_state, new_bid)
    end

    test "bid not lower than previous bids", %{
      auction: auction,
      supplier1: supplier1,
      supplier2: supplier2
    } do
      auction_id = auction.id

      prev_bid = %AuctionBid{
        amount: 2.00,
        supplier_id: supplier1,
        auction_id: auction_id,
        time_entered: DateTime.utc_now()
      }

      current_state = %AuctionState{
        auction_id: auction_id,
        status: :open,
        lowest_bids: [prev_bid],
        active_bids: [prev_bid],
        minimum_bids: [],
        winning_bid: nil,
        bids: [prev_bid]
      }

      new_bid = %AuctionBid{
        amount: 3.00,
        supplier_id: supplier2,
        auction_id: auction_id,
        time_entered: DateTime.utc_now()
      }

      assert {%AuctionState{
                auction_id: ^auction_id,
                status: :open,
                winning_bid: nil,
                lowest_bids: [^prev_bid, ^new_bid],
                bids: [^new_bid, ^prev_bid],
                minimum_bids: []
              }, _events} = AuctionBidCalculator.process(current_state, new_bid)
    end

    test "entering a bid invalidates previous bid from a supplier", %{
      auction: auction,
      supplier1: supplier1
    } do
      auction_id = auction.id

      prev_bid = %AuctionBid{
        amount: 2.00,
        supplier_id: supplier1,
        auction_id: auction_id,
        time_entered: DateTime.utc_now()
      }

      current_state = %AuctionState{
        auction_id: auction_id,
        status: :open,
        lowest_bids: [prev_bid],
        active_bids: [prev_bid],
        minimum_bids: [],
        winning_bid: nil,
        bids: [prev_bid]
      }

      new_bid = %AuctionBid{
        amount: 3.00,
        supplier_id: supplier1,
        auction_id: auction_id,
        time_entered: DateTime.utc_now()
      }

      updated_prev_bid = %AuctionBid{prev_bid | active: false}

      assert {%AuctionState{
                auction_id: ^auction_id,
                status: :open,
                winning_bid: nil,
                lowest_bids: [^new_bid],
                active_bids: [^new_bid],
                bids: [^new_bid, ^updated_prev_bid],
                minimum_bids: [],
                inactive_bids: [^updated_prev_bid]
              }, _events} = AuctionBidCalculator.process(current_state, new_bid)
    end
  end

  describe "auto bidding" do
    test "entering a auto bid before the auction starts", %{
      auction: auction,
      supplier1: supplier1,
      supplier2: supplier2
    } do
      auction_id = auction.id

      supplier1_bid = %AuctionBid{
        amount: 2.00,
        min_amount: 1.00,
        supplier_id: supplier1,
        auction_id: auction_id,
        time_entered: DateTime.utc_now()
      }

      supplier2_bid = %AuctionBid{
        amount: 2.00,
        min_amount: 1.50,
        supplier_id: supplier2,
        auction_id: auction_id,
        time_entered: DateTime.utc_now()
      }

      initial_state = %AuctionState{
        auction_id: auction_id,
        status: :pending,
        lowest_bids: [],
        minimum_bids: [],
        winning_bid: nil,
        bids: []
      }

      {state, _events} = AuctionBidCalculator.process(initial_state, supplier1_bid)
      {current_state, _events} = AuctionBidCalculator.process(state, supplier2_bid)

      assert %AuctionState{
               auction_id: ^auction_id,
               status: :pending,
               winning_bid: nil,
               lowest_bids: [],
               bids: [],
               minimum_bids: [^supplier2_bid, ^supplier1_bid],
               inactive_bids: []
             } = current_state
    end

    test "minimum bids get processed at auction start", %{
      auction: auction,
      supplier1: supplier1,
      supplier2: supplier2
    } do
      auction_id = auction.id

      supplier1_bid = %AuctionBid{
        amount: 2.00,
        min_amount: 1.00,
        supplier_id: supplier1,
        auction_id: auction_id,
        time_entered: DateTime.utc_now()
      }

      supplier2_bid = %AuctionBid{
        amount: 2.00,
        min_amount: 1.50,
        supplier_id: supplier2,
        auction_id: auction_id,
        time_entered: DateTime.utc_now()
      }

      initial_state = %AuctionState{
        auction_id: auction_id,
        status: :pending,
        lowest_bids: [],
        minimum_bids: [supplier2_bid, supplier1_bid],
        active_bids: [],
        winning_bid: nil,
        bids: []
      }

      state = %AuctionState{initial_state | status: :open}
      {new_state, _events} = AuctionBidCalculator.process(state)

      assert [
               %AuctionBid{amount: 1.25, min_amount: 1.00, supplier_id: ^supplier1},
               %AuctionBid{amount: 1.50, min_amount: 1.50, supplier_id: ^supplier2}
             ] = new_state.lowest_bids

      inactive_bids =
        Enum.map(new_state.inactive_bids, fn bid -> {bid.amount, bid.supplier_id} end)

      # both initial auto bids get lowered, so the originals are invalidated.
      assert [
               {2.0, ^supplier1},
               {2.0, ^supplier2}
             ] = inactive_bids
    end

    test "minimum bids get processed after auction start with matching lowest bid", %{
      auction: auction,
      supplier1: supplier1,
      supplier2: supplier2
    } do
      auction_id = auction.id

      supplier1_bid1 = %AuctionBid{
        amount: 2.00,
        min_amount: 1.00,
        supplier_id: supplier1,
        auction_id: auction_id,
        time_entered: DateTime.utc_now()
      }

      supplier2_bid1 = %AuctionBid{
        amount: 2.00,
        min_amount: 1.50,
        supplier_id: supplier2,
        auction_id: auction_id,
        time_entered: DateTime.utc_now()
      }

      supplier2_bid2 = %AuctionBid{
        amount: 1.25,
        min_amount: 0.75,
        supplier_id: supplier2,
        auction_id: auction_id,
        time_entered: DateTime.utc_now()
      }

      initial_state = %AuctionState{
        auction_id: auction_id,
        status: :pending,
        lowest_bids: [],
        minimum_bids: [supplier2_bid1, supplier1_bid1],
        active_bids: [],
        winning_bid: nil,
        bids: []
      }

      state = %AuctionState{initial_state | status: :open}
      {state, _events} = AuctionBidCalculator.process(state)
      {state, _events} = AuctionBidCalculator.process(state, supplier2_bid2)
      {final_state, _events} = AuctionBidCalculator.process(state)

      lowest_bids = Enum.map(final_state.lowest_bids, fn bid -> {bid.amount, bid.supplier_id} end)
      assert [{0.75, ^supplier2}, {1.00, ^supplier1} | _rest] = lowest_bids
    end

    test "after auction start with lower bid than current lowest", %{
      auction: auction,
      supplier1: supplier1,
      supplier2: supplier2
    } do
      auction_id = auction.id

      supplier1_bid1 = %AuctionBid{
        amount: 2.00,
        min_amount: 1.00,
        supplier_id: supplier1,
        auction_id: auction_id,
        time_entered: DateTime.utc_now()
      }

      supplier2_bid1 = %AuctionBid{
        amount: 2.00,
        min_amount: 1.50,
        supplier_id: supplier2,
        auction_id: auction_id,
        time_entered: DateTime.utc_now()
      }

      supplier2_bid2 = %AuctionBid{
        amount: 1.00,
        min_amount: 0.75,
        supplier_id: supplier2,
        auction_id: auction_id,
        time_entered: DateTime.utc_now()
      }

      initial_state = %AuctionState{
        auction_id: auction_id,
        status: :pending,
        lowest_bids: [],
        minimum_bids: [supplier2_bid1, supplier1_bid1],
        active_bids: [],
        winning_bid: nil,
        bids: []
      }

      state = %AuctionState{initial_state | status: :open}
      {state, _events} = AuctionBidCalculator.process(state)
      {state, _events} = AuctionBidCalculator.process(state, supplier2_bid2)
      {final_state, _events} = AuctionBidCalculator.process(state)

      lowest_bids = Enum.map(final_state.lowest_bids, fn bid -> {bid.amount, bid.supplier_id} end)
      assert [{0.75, ^supplier2}, {1.00, ^supplier1} | _rest] = lowest_bids
    end

    test "after auction start with lower bid that is normal bid", %{
      auction: auction,
      supplier1: supplier1,
      supplier2: supplier2
    } do
      auction_id = auction.id

      supplier1_bid1 = %AuctionBid{
        amount: 2.00,
        min_amount: 1.00,
        supplier_id: supplier1,
        auction_id: auction_id,
        time_entered: DateTime.utc_now()
      }

      supplier2_bid1 = %AuctionBid{
        amount: 2.00,
        min_amount: 1.50,
        supplier_id: supplier2,
        auction_id: auction_id,
        time_entered: DateTime.utc_now()
      }

      supplier2_bid2 = %AuctionBid{
        amount: 1.00,
        min_amount: nil,
        supplier_id: supplier2,
        auction_id: auction_id,
        time_entered: DateTime.utc_now()
      }

      initial_state = %AuctionState{
        auction_id: auction_id,
        status: :pending,
        lowest_bids: [],
        minimum_bids: [supplier2_bid1, supplier1_bid1],
        active_bids: [],
        winning_bid: nil,
        bids: []
      }

      state = %AuctionState{initial_state | status: :open}
      {state, _events} = AuctionBidCalculator.process(state)
      {state, _events} = AuctionBidCalculator.process(state, supplier2_bid2)
      {final_state, _events} = AuctionBidCalculator.process(state)

      lowest_bids = Enum.map(final_state.lowest_bids, fn bid -> {bid.amount, bid.supplier_id} end)
      assert [{1.00, ^supplier1}, {1.00, ^supplier2} | _rest] = lowest_bids
    end

    test "after auction start with higher bid that is normal bid", %{
      auction: auction,
      supplier1: supplier1,
      supplier2: supplier2
    } do
      auction_id = auction.id

      supplier1_bid1 = %AuctionBid{
        amount: 2.00,
        min_amount: 1.00,
        supplier_id: supplier1,
        auction_id: auction_id,
        time_entered: DateTime.utc_now()
      }

      supplier2_bid1 = %AuctionBid{
        amount: 2.00,
        min_amount: 1.50,
        supplier_id: supplier2,
        auction_id: auction_id,
        time_entered: DateTime.utc_now()
      }

      supplier2_bid2 = %AuctionBid{
        amount: 2.50,
        min_amount: nil,
        supplier_id: supplier2,
        auction_id: auction_id,
        time_entered: DateTime.utc_now()
      }

      initial_state = %AuctionState{
        auction_id: auction_id,
        status: :pending,
        lowest_bids: [],
        minimum_bids: [supplier2_bid1, supplier1_bid1],
        active_bids: [],
        winning_bid: nil,
        bids: []
      }

      state = %AuctionState{initial_state | status: :open}
      {state, _events} = AuctionBidCalculator.process(state)
      {state, _events} = AuctionBidCalculator.process(state, supplier2_bid2)
      {final_state, _events} = AuctionBidCalculator.process(state)

      lowest_bids = Enum.map(final_state.lowest_bids, fn bid -> {bid.amount, bid.supplier_id} end)
      assert [{1.25, ^supplier1}, {2.50, ^supplier2} | _rest] = lowest_bids
    end

    test "after auction start with lower, beatable normal bid lowers all auto bids and is beaten",
         %{
           auction: auction,
           supplier1: supplier1,
           supplier2: supplier2
         } do
      auction_id = auction.id

      supplier1_bid1 = %AuctionBid{
        amount: 2.00,
        min_amount: 1.00,
        supplier_id: supplier1,
        auction_id: auction_id,
        time_entered: DateTime.utc_now()
      }

      supplier2_bid1 = %AuctionBid{
        amount: 2.00,
        min_amount: 1.50,
        supplier_id: supplier2,
        auction_id: auction_id,
        time_entered: DateTime.utc_now()
      }

      supplier2_bid2 = %AuctionBid{
        amount: 1.25,
        min_amount: nil,
        supplier_id: supplier2,
        auction_id: auction_id,
        time_entered: DateTime.utc_now()
      }

      initial_state = %AuctionState{
        auction_id: auction_id,
        status: :pending,
        lowest_bids: [],
        minimum_bids: [supplier2_bid1, supplier1_bid1],
        active_bids: [],
        winning_bid: nil,
        bids: []
      }

      state = %AuctionState{initial_state | status: :open}
      {state, _events} = AuctionBidCalculator.process(state)
      {state, _events} = AuctionBidCalculator.process(state, supplier2_bid2)
      {final_state, _events} = AuctionBidCalculator.process(state)

      lowest_bids = Enum.map(final_state.lowest_bids, fn bid -> {bid.amount, bid.supplier_id} end)
      assert [{1.00, ^supplier1}, {1.25, ^supplier2} | _rest] = lowest_bids
    end

    test "after auction start with lower, unbeatable normal bid lowers all auto bids", %{
      auction: auction,
      supplier1: supplier1,
      supplier2: supplier2
    } do
      auction_id = auction.id

      supplier1_bid1 = %AuctionBid{
        amount: 2.00,
        min_amount: 1.00,
        supplier_id: supplier1,
        auction_id: auction_id,
        time_entered: DateTime.utc_now()
      }

      supplier2_bid1 = %AuctionBid{
        amount: 2.00,
        min_amount: 1.50,
        supplier_id: supplier2,
        auction_id: auction_id,
        time_entered: DateTime.utc_now()
      }

      supplier2_bid2 = %AuctionBid{
        amount: 0.75,
        min_amount: nil,
        supplier_id: supplier2,
        auction_id: auction_id,
        time_entered: DateTime.utc_now()
      }

      initial_state = %AuctionState{
        auction_id: auction_id,
        status: :pending,
        lowest_bids: [],
        minimum_bids: [supplier2_bid1, supplier1_bid1],
        active_bids: [],
        winning_bid: nil,
        bids: []
      }

      state = %AuctionState{initial_state | status: :open}
      {state, _events} = AuctionBidCalculator.process(state)
      {state, _events} = AuctionBidCalculator.process(state, supplier2_bid2)
      {final_state, _events} = AuctionBidCalculator.process(state)

      lowest_bids = Enum.map(final_state.lowest_bids, fn bid -> {bid.amount, bid.supplier_id} end)
      assert [{0.75, ^supplier2}, {1.00, ^supplier1} | _rest] = lowest_bids
    end

    test "with multiple matching lowest bids", %{
      auction: auction,
      supplier1: supplier1,
      supplier2: supplier2,
      supplier3: supplier3
    } do
      auction_id = auction.id

      supplier1_bid1 = %AuctionBid{
        amount: nil,
        min_amount: 2.00,
        supplier_id: supplier1,
        auction_id: auction_id,
        time_entered: DateTime.utc_now()
      }

      supplier2_bid1 = %AuctionBid{
        amount: nil,
        min_amount: 2.00,
        supplier_id: supplier2,
        auction_id: auction_id,
        time_entered: DateTime.utc_now()
      }

      supplier3_bid1 = %AuctionBid{
        amount: nil,
        min_amount: 3.50,
        supplier_id: supplier3,
        auction_id: auction_id,
        time_entered: DateTime.utc_now()
      }

      initial_state = %AuctionState{
        auction_id: auction_id,
        status: :pending,
        lowest_bids: [],
        minimum_bids: [],
        active_bids: [],
        winning_bid: nil,
        bids: []
      }

      state = %AuctionState{initial_state | status: :open}
      {state, _events} = AuctionBidCalculator.process(state)
      {state, _events} = AuctionBidCalculator.process(state, supplier3_bid1)
      {state, _events} = AuctionBidCalculator.process(state, supplier1_bid1)
      {final_state, _events} = AuctionBidCalculator.process(state, supplier2_bid1)

      lowest_bids = Enum.map(final_state.lowest_bids, fn bid -> {bid.amount, bid.supplier_id} end)
      assert [{2.00, ^supplier1}, {2.00, ^supplier2}, {3.50, ^supplier3}] = lowest_bids
    end

    test "with only multiple matching lowest bids", %{
      auction: auction,
      supplier1: supplier1,
      supplier2: supplier2
    } do
      auction_id = auction.id

      supplier1_bid1 = %AuctionBid{
        amount: 2.75,
        min_amount: 2.00,
        supplier_id: supplier1,
        auction_id: auction_id,
        time_entered: DateTime.utc_now()
      }

      supplier2_bid1 = %AuctionBid{
        amount: nil,
        min_amount: 2.00,
        supplier_id: supplier2,
        auction_id: auction_id,
        time_entered: DateTime.utc_now()
      }

      initial_state = %AuctionState{
        auction_id: auction_id,
        status: :pending,
        lowest_bids: [],
        minimum_bids: [],
        active_bids: [],
        winning_bid: nil,
        bids: []
      }

      state = %AuctionState{initial_state | status: :open}
      {state, _events} = AuctionBidCalculator.process(state)
      {state, _events} = AuctionBidCalculator.process(state, supplier1_bid1)
      {state, _events} = AuctionBidCalculator.process(state, supplier2_bid1)

      lowest_bids = Enum.map(state.lowest_bids, fn bid -> {bid.amount, bid.supplier_id} end)
      assert [{2.00, ^supplier1}, {2.00, ^supplier2}] = lowest_bids
    end
  end

  describe "events" do
    test "updated auto bids do fire bid events", %{
      auction: auction,
      supplier1: supplier1,
      supplier2: supplier2
    } do
      auction_id = auction.id

      supplier1_bid1 = %AuctionBid{
        amount: 2.00,
        min_amount: 1.75,
        supplier_id: supplier1,
        auction_id: auction_id,
        time_entered: DateTime.utc_now()
      }

      supplier2_bid1 = %AuctionBid{
        amount: 1.50,
        min_amount: 1.25,
        supplier_id: supplier2,
        auction_id: auction_id,
        time_entered: DateTime.utc_now()
      }

      supplier1_bid2 = %AuctionBid{
        amount: nil,
        min_amount: 1.00,
        supplier_id: supplier1,
        auction_id: auction_id,
        time_entered: DateTime.utc_now()
      }

      initial_state = %AuctionState{
        auction_id: auction_id,
        status: :pending,
        lowest_bids: [],
        minimum_bids: [],
        active_bids: [],
        winning_bid: nil,
        bids: []
      }

      {state, _} = AuctionBidCalculator.process(initial_state, supplier2_bid1)
      {state, _} = AuctionBidCalculator.process(state, supplier1_bid1)
      {state, _events} = AuctionBidCalculator.process(%AuctionState{state | status: :open})
      {_state, events} = AuctionBidCalculator.process(state, supplier1_bid2)

      assert [
               %AuctionEvent{
                 type: :auto_bid_placed,
                 auction_id: auction_id,
                 data: %{bid: %AuctionBid{amount: 1.00, supplier_id: ^supplier1}}
               },
               %AuctionEvent{
                 type: :auto_bid_placed,
                 auction_id: auction_id,
                 data: %{bid: %AuctionBid{amount: 1.25, supplier_id: ^supplier2}}
               }
             ] = events
    end

    test "unchanged auto bids do not fire bid events", %{
      auction: auction,
      supplier1: supplier1,
      supplier2: supplier2
    } do
      auction_id = auction.id

      supplier1_bid1 = %AuctionBid{
        amount: 2.50,
        min_amount: 2.00,
        supplier_id: supplier1,
        auction_id: auction_id,
        time_entered: DateTime.utc_now()
      }

      supplier2_bid1 = %AuctionBid{
        amount: 2.25,
        min_amount: 2.00,
        supplier_id: supplier2,
        auction_id: auction_id,
        time_entered: DateTime.utc_now()
      }

      supplier1_bid2 = %AuctionBid{
        amount: nil,
        min_amount: 1.75,
        supplier_id: supplier1,
        auction_id: auction_id,
        time_entered: DateTime.utc_now()
      }

      initial_state = %AuctionState{
        auction_id: auction_id,
        status: :pending,
        lowest_bids: [],
        minimum_bids: [],
        active_bids: [],
        winning_bid: nil,
        bids: []
      }

      {state, _} = AuctionBidCalculator.process(initial_state, supplier2_bid1)
      {state, _} = AuctionBidCalculator.process(state, supplier1_bid1)
      {state, _} = AuctionBidCalculator.process(%AuctionState{state | status: :open})
      {_state, events} = AuctionBidCalculator.process(state, supplier1_bid2)

      assert [
               %AuctionEvent{
                 type: :auto_bid_placed,
                 auction_id: ^auction_id,
                 data: %{bid: %AuctionBid{amount: 1.75, supplier_id: ^supplier1}}
               }
             ] = events
    end
  end

  describe "pending auction" do
    test "does not lower auto bids", %{
      auction: auction,
      supplier1: supplier1,
      supplier2: supplier2
    } do
      auction_id = auction.id

      supplier1_bid1 = %AuctionBid{
        amount: 2.00,
        min_amount: 1.00,
        supplier_id: supplier1,
        auction_id: auction_id,
        time_entered: DateTime.utc_now()
      }

      supplier2_bid1 = %AuctionBid{
        amount: 2.00,
        min_amount: 1.50,
        supplier_id: supplier2,
        auction_id: auction_id,
        time_entered: DateTime.utc_now()
      }

      initial_state = %AuctionState{
        auction_id: auction_id,
        status: :pending,
        lowest_bids: [],
        minimum_bids: [supplier2_bid1, supplier1_bid1],
        active_bids: [],
        winning_bid: nil,
        bids: []
      }

      {state, _events} = AuctionBidCalculator.process(initial_state)

      assert initial_state == state
    end
  end
end
