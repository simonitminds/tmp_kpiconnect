defmodule Oceanconnect.Auctions.AuctionBidCalculatorTest do
  use Oceanconnect.DataCase
  alias Oceanconnect.Auctions.AuctionBidCalculator
  alias Oceanconnect.Auctions.{AuctionBid, AuctionEvent, AuctionStore.ProductBidState}

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

    vessel_fuel = List.first(auction.auction_vessel_fuels)

    {:ok,
     %{
       auction: auction,
       vessel_fuel_id: vessel_fuel.id,
       supplier1: supplier_company.id,
       supplier2: supplier2_company.id,
       supplier3: supplier3_company.id
     }}
  end

  describe "bidding" do
    test "with no previous bids", %{
      auction: auction,
      vessel_fuel_id: vessel_fuel_id,
      supplier1: supplier1
    } do
      auction_id = auction.id

      current_state = %ProductBidState{
        auction_id: auction_id,
        lowest_bids: [],
        minimum_bids: [],
        bids: []
      }

      new_bid = %AuctionBid{
        amount: 2.00,
        supplier_id: supplier1,
        auction_id: auction_id,
        vessel_fuel_id: vessel_fuel_id,
        active: true
      }

      assert {%ProductBidState{
                auction_id: ^auction_id,
                lowest_bids: [^new_bid],
                bids: [^new_bid],
                active_bids: [^new_bid],
                minimum_bids: [],
                inactive_bids: []
              }, _events} = AuctionBidCalculator.process(current_state, new_bid, :open)
    end

    test "out bidding a previous bid", %{
      auction: auction,
      vessel_fuel_id: vessel_fuel_id,
      supplier1: supplier1,
      supplier2: supplier2
    } do
      auction_id = auction.id

      prev_bid = %AuctionBid{
        amount: 2.00,
        supplier_id: supplier1,
        vessel_fuel_id: vessel_fuel_id,
        auction_id: auction_id
      }

      current_state = %ProductBidState{
        auction_id: auction_id,
        lowest_bids: [prev_bid],
        minimum_bids: [],
        active_bids: [prev_bid],
        bids: [prev_bid]
      }

      new_bid = %AuctionBid{
        amount: 1.75,
        supplier_id: supplier2,
        vessel_fuel_id: vessel_fuel_id,
        auction_id: auction_id
      }

      assert {%ProductBidState{
                auction_id: ^auction_id,
                lowest_bids: [^new_bid, ^prev_bid],
                active_bids: [^new_bid, ^prev_bid],
                bids: [^new_bid, ^prev_bid],
                minimum_bids: []
              }, _events} = AuctionBidCalculator.process(current_state, new_bid, :open)
    end

    test "entering a matching bid", %{
      auction: auction,
      vessel_fuel_id: vessel_fuel_id,
      supplier1: supplier1,
      supplier2: supplier2
    } do
      auction_id = auction.id

      prev_bid = %AuctionBid{
        amount: 2.00,
        supplier_id: supplier1,
        auction_id: auction_id,
        vessel_fuel_id: vessel_fuel_id,
        time_entered: DateTime.utc_now(),
        original_time_entered: DateTime.utc_now()
      }

      current_state = %ProductBidState{
        auction_id: auction_id,
        lowest_bids: [prev_bid],
        active_bids: [prev_bid],
        minimum_bids: [],
        bids: [prev_bid]
      }

      new_bid = %AuctionBid{
        amount: 2.00,
        supplier_id: supplier2,
        auction_id: auction_id,
        vessel_fuel_id: vessel_fuel_id,
        time_entered: DateTime.utc_now(),
        original_time_entered: DateTime.utc_now()
      }

      assert {%ProductBidState{
                auction_id: ^auction_id,
                lowest_bids: [^prev_bid, ^new_bid],
                bids: [^new_bid, ^prev_bid],
                minimum_bids: []
              }, _events} = AuctionBidCalculator.process(current_state, new_bid, :open)
    end

    test "bid not lower than previous bids", %{
      auction: auction,
      vessel_fuel_id: vessel_fuel_id,
      supplier1: supplier1,
      supplier2: supplier2
    } do
      auction_id = auction.id

      prev_bid = %AuctionBid{
        amount: 2.00,
        supplier_id: supplier1,
        auction_id: auction_id,
        vessel_fuel_id: vessel_fuel_id,
        time_entered: DateTime.utc_now(),
        original_time_entered: DateTime.utc_now()
      }

      current_state = %ProductBidState{
        auction_id: auction_id,
        lowest_bids: [prev_bid],
        active_bids: [prev_bid],
        minimum_bids: [],
        bids: [prev_bid]
      }

      new_bid = %AuctionBid{
        amount: 3.00,
        supplier_id: supplier2,
        auction_id: auction_id,
        vessel_fuel_id: vessel_fuel_id,
        time_entered: DateTime.utc_now(),
        original_time_entered: DateTime.utc_now()
      }

      assert {%ProductBidState{
                auction_id: ^auction_id,
                lowest_bids: [^prev_bid, ^new_bid],
                bids: [^new_bid, ^prev_bid],
                minimum_bids: []
              }, _events} = AuctionBidCalculator.process(current_state, new_bid, :open)
    end

    test "entering a bid invalidates previous bid from a supplier", %{
      auction: auction,
      vessel_fuel_id: vessel_fuel_id,
      supplier1: supplier1
    } do
      auction_id = auction.id

      prev_bid = %AuctionBid{
        amount: 2.00,
        supplier_id: supplier1,
        auction_id: auction_id,
        vessel_fuel_id: vessel_fuel_id,
        time_entered: DateTime.utc_now(),
        original_time_entered: DateTime.utc_now()
      }

      current_state = %ProductBidState{
        auction_id: auction_id,
        lowest_bids: [prev_bid],
        active_bids: [prev_bid],
        minimum_bids: [],
        bids: [prev_bid]
      }

      new_bid = %AuctionBid{
        amount: 3.00,
        supplier_id: supplier1,
        auction_id: auction_id,
        vessel_fuel_id: vessel_fuel_id,
        time_entered: DateTime.utc_now(),
        original_time_entered: DateTime.utc_now()
      }

      updated_prev_bid = %AuctionBid{prev_bid | active: false}

      assert {%ProductBidState{
                auction_id: ^auction_id,
                lowest_bids: [^new_bid],
                active_bids: [^new_bid],
                bids: [^new_bid, ^updated_prev_bid],
                minimum_bids: [],
                inactive_bids: [^updated_prev_bid]
              }, _events} = AuctionBidCalculator.process(current_state, new_bid, :open)
    end

    test "revoking a bid invalidates that bid", %{
      auction: auction,
      vessel_fuel_id: vessel_fuel_id,
      supplier1: supplier1,
      supplier2: supplier2
    } do
      auction_id = auction.id

      supplier1_bid = %AuctionBid{
        amount: 1.75,
        supplier_id: supplier1,
        auction_id: auction_id,
        vessel_fuel_id: vessel_fuel_id,
        time_entered: DateTime.utc_now(),
        original_time_entered: DateTime.utc_now()
      }

      supplier2_bid = %AuctionBid{
        amount: 2.00,
        supplier_id: supplier2,
        auction_id: auction_id,
        vessel_fuel_id: vessel_fuel_id,
        time_entered: DateTime.utc_now(),
        original_time_entered: DateTime.utc_now()
      }

      current_state = %ProductBidState{
        auction_id: auction_id,
        lowest_bids: [supplier1_bid, supplier2_bid],
        active_bids: [supplier2_bid, supplier1_bid],
        minimum_bids: [],
        bids: [supplier2_bid, supplier1_bid],
        inactive_bids: []
      }

      deactivated_supplier1_bid = %AuctionBid{supplier1_bid | active: false}

      assert %ProductBidState{
               auction_id: ^auction_id,
               active_bids: [^supplier2_bid],
               bids: [^supplier2_bid, ^deactivated_supplier1_bid],
               inactive_bids: [^deactivated_supplier1_bid],
               lowest_bids: [^supplier2_bid],
               minimum_bids: []
             } = AuctionBidCalculator.revoke_supplier_bids(current_state, supplier1)
    end
  end

  describe "auto bidding" do
    test "entering a auto bid before the auction starts", %{
      auction: auction,
      vessel_fuel_id: vessel_fuel_id,
      supplier1: supplier1,
      supplier2: supplier2
    } do
      auction_id = auction.id

      supplier1_bid = %AuctionBid{
        amount: 2.00,
        min_amount: 1.00,
        supplier_id: supplier1,
        auction_id: auction_id,
        vessel_fuel_id: vessel_fuel_id,
        time_entered: DateTime.utc_now(),
        original_time_entered: DateTime.utc_now()
      }

      supplier2_bid = %AuctionBid{
        amount: 2.00,
        min_amount: 1.50,
        supplier_id: supplier2,
        auction_id: auction_id,
        vessel_fuel_id: vessel_fuel_id,
        time_entered: DateTime.utc_now(),
        original_time_entered: DateTime.utc_now()
      }

      initial_state = %ProductBidState{
        auction_id: auction_id,
        lowest_bids: [],
        minimum_bids: [],
        bids: []
      }

      {state, _events} = AuctionBidCalculator.process(initial_state, supplier1_bid, :pending)
      {current_state, _events} = AuctionBidCalculator.process(state, supplier2_bid, :pending)

      assert %ProductBidState{
               auction_id: ^auction_id,
               lowest_bids: [],
               bids: [^supplier2_bid, ^supplier1_bid],
               minimum_bids: [^supplier2_bid, ^supplier1_bid],
               inactive_bids: []
             } = current_state
    end

    test "minimum bids get processed at auction start", %{
      auction: auction,
      vessel_fuel_id: vessel_fuel_id,
      supplier1: supplier1,
      supplier2: supplier2
    } do
      auction_id = auction.id

      supplier1_bid = %AuctionBid{
        amount: 2.00,
        min_amount: 1.00,
        supplier_id: supplier1,
        auction_id: auction_id,
        vessel_fuel_id: vessel_fuel_id,
        time_entered: DateTime.utc_now(),
        original_time_entered: DateTime.utc_now()
      }

      supplier2_bid = %AuctionBid{
        amount: 2.00,
        min_amount: 1.50,
        supplier_id: supplier2,
        auction_id: auction_id,
        vessel_fuel_id: vessel_fuel_id,
        time_entered: DateTime.utc_now(),
        original_time_entered: DateTime.utc_now()
      }

      initial_state = %ProductBidState{
        auction_id: auction_id,
        lowest_bids: [],
        minimum_bids: [supplier2_bid, supplier1_bid],
        active_bids: [],
        bids: []
      }

      {new_state, _events} = AuctionBidCalculator.process(initial_state, :open)

      assert [
               %AuctionBid{
                 amount: 1.25,
                 min_amount: 1.00,
                 vessel_fuel_id: ^vessel_fuel_id,
                 supplier_id: ^supplier1
               },
               %AuctionBid{
                 amount: 1.50,
                 min_amount: 1.50,
                 vessel_fuel_id: ^vessel_fuel_id,
                 supplier_id: ^supplier2
               }
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
      vessel_fuel_id: vessel_fuel_id,
      supplier1: supplier1,
      supplier2: supplier2
    } do
      auction_id = auction.id

      supplier1_bid1 = %AuctionBid{
        amount: 2.00,
        min_amount: 1.00,
        supplier_id: supplier1,
        auction_id: auction_id,
        vessel_fuel_id: vessel_fuel_id,
        time_entered: DateTime.utc_now(),
        original_time_entered: DateTime.utc_now()
      }

      supplier2_bid1 = %AuctionBid{
        amount: 2.00,
        min_amount: 1.50,
        supplier_id: supplier2,
        auction_id: auction_id,
        vessel_fuel_id: vessel_fuel_id,
        time_entered: DateTime.utc_now(),
        original_time_entered: DateTime.utc_now()
      }

      supplier2_bid2 = %AuctionBid{
        amount: 1.25,
        min_amount: 0.75,
        supplier_id: supplier2,
        auction_id: auction_id,
        vessel_fuel_id: vessel_fuel_id,
        time_entered: DateTime.utc_now(),
        original_time_entered: DateTime.utc_now()
      }

      initial_state = %ProductBidState{
        auction_id: auction_id,
        lowest_bids: [],
        minimum_bids: [supplier2_bid1, supplier1_bid1],
        active_bids: [],
        bids: []
      }

      {state, _events} = AuctionBidCalculator.process(initial_state, :open)
      {state, _events} = AuctionBidCalculator.process(state, supplier2_bid2, :open)
      {final_state, _events} = AuctionBidCalculator.process(state, :open)

      lowest_bids = Enum.map(final_state.lowest_bids, fn bid -> {bid.amount, bid.supplier_id} end)
      assert [{0.75, ^supplier2}, {1.00, ^supplier1} | _rest] = lowest_bids
    end

    test "after auction start with lower bid than current lowest", %{
      auction: auction,
      vessel_fuel_id: vessel_fuel_id,
      supplier1: supplier1,
      supplier2: supplier2
    } do
      auction_id = auction.id

      supplier1_bid1 = %AuctionBid{
        amount: 2.00,
        min_amount: 1.00,
        supplier_id: supplier1,
        auction_id: auction_id,
        vessel_fuel_id: vessel_fuel_id,
        time_entered: DateTime.utc_now(),
        original_time_entered: DateTime.utc_now()
      }

      supplier2_bid1 = %AuctionBid{
        amount: 2.00,
        min_amount: 1.50,
        supplier_id: supplier2,
        auction_id: auction_id,
        vessel_fuel_id: vessel_fuel_id,
        time_entered: DateTime.utc_now(),
        original_time_entered: DateTime.utc_now()
      }

      supplier2_bid2 = %AuctionBid{
        amount: 1.00,
        min_amount: 0.75,
        supplier_id: supplier2,
        auction_id: auction_id,
        vessel_fuel_id: vessel_fuel_id,
        time_entered: DateTime.utc_now(),
        original_time_entered: DateTime.utc_now()
      }

      initial_state = %ProductBidState{
        auction_id: auction_id,
        lowest_bids: [],
        minimum_bids: [supplier2_bid1, supplier1_bid1],
        active_bids: [],
        bids: []
      }

      {state, _events} = AuctionBidCalculator.process(initial_state, :open)
      {state, _events} = AuctionBidCalculator.process(state, supplier2_bid2, :open)
      {final_state, _events} = AuctionBidCalculator.process(state, :open)

      lowest_bids = Enum.map(final_state.lowest_bids, fn bid -> {bid.amount, bid.supplier_id} end)
      assert [{0.75, ^supplier2}, {1.00, ^supplier1} | _rest] = lowest_bids
    end

    test "after auction start with lower bid that is normal bid", %{
      auction: auction,
      vessel_fuel_id: vessel_fuel_id,
      supplier1: supplier1,
      supplier2: supplier2
    } do
      auction_id = auction.id

      supplier1_bid1 = %AuctionBid{
        amount: 2.00,
        min_amount: 1.00,
        supplier_id: supplier1,
        auction_id: auction_id,
        vessel_fuel_id: vessel_fuel_id,
        time_entered: DateTime.utc_now(),
        original_time_entered: DateTime.utc_now()
      }

      supplier2_bid1 = %AuctionBid{
        amount: 2.00,
        min_amount: 1.50,
        supplier_id: supplier2,
        auction_id: auction_id,
        vessel_fuel_id: vessel_fuel_id,
        time_entered: DateTime.utc_now(),
        original_time_entered: DateTime.utc_now()
      }

      supplier2_bid2 = %AuctionBid{
        amount: 1.00,
        min_amount: nil,
        supplier_id: supplier2,
        auction_id: auction_id,
        vessel_fuel_id: vessel_fuel_id,
        time_entered: DateTime.utc_now(),
        original_time_entered: DateTime.utc_now()
      }

      initial_state = %ProductBidState{
        auction_id: auction_id,
        lowest_bids: [],
        minimum_bids: [supplier2_bid1, supplier1_bid1],
        active_bids: [],
        bids: []
      }

      {state, _events} = AuctionBidCalculator.process(initial_state, :open)
      {state, _events} = AuctionBidCalculator.process(state, supplier2_bid2, :open)
      {final_state, _events} = AuctionBidCalculator.process(state, :open)

      lowest_bids = Enum.map(final_state.lowest_bids, fn bid -> {bid.amount, bid.supplier_id} end)
      assert [{1.00, ^supplier1}, {1.00, ^supplier2} | _rest] = lowest_bids
    end

    test "after auction start with higher bid that is normal bid", %{
      auction: auction,
      vessel_fuel_id: vessel_fuel_id,
      supplier1: supplier1,
      supplier2: supplier2
    } do
      auction_id = auction.id

      supplier1_bid1 = %AuctionBid{
        amount: 2.00,
        min_amount: 1.00,
        supplier_id: supplier1,
        auction_id: auction_id,
        vessel_fuel_id: vessel_fuel_id,
        time_entered: DateTime.utc_now(),
        original_time_entered: DateTime.utc_now()
      }

      supplier2_bid1 = %AuctionBid{
        amount: 2.00,
        min_amount: 1.50,
        supplier_id: supplier2,
        auction_id: auction_id,
        vessel_fuel_id: vessel_fuel_id,
        time_entered: DateTime.utc_now(),
        original_time_entered: DateTime.utc_now()
      }

      supplier2_bid2 = %AuctionBid{
        amount: 2.50,
        min_amount: nil,
        supplier_id: supplier2,
        auction_id: auction_id,
        vessel_fuel_id: vessel_fuel_id,
        time_entered: DateTime.utc_now(),
        original_time_entered: DateTime.utc_now()
      }

      initial_state = %ProductBidState{
        auction_id: auction_id,
        lowest_bids: [],
        minimum_bids: [supplier2_bid1, supplier1_bid1],
        active_bids: [],
        bids: []
      }

      {state, _events} = AuctionBidCalculator.process(initial_state, :open)
      {state, _events} = AuctionBidCalculator.process(state, supplier2_bid2, :open)
      {final_state, _events} = AuctionBidCalculator.process(state, :open)

      lowest_bids = Enum.map(final_state.lowest_bids, fn bid -> {bid.amount, bid.supplier_id} end)
      assert [{1.25, ^supplier1}, {2.50, ^supplier2} | _rest] = lowest_bids
    end

    test "after auction start with lower, beatable normal bid lowers all auto bids and is beaten",
         %{
           auction: auction,
           vessel_fuel_id: vessel_fuel_id,
           supplier1: supplier1,
           supplier2: supplier2
         } do
      auction_id = auction.id

      supplier1_bid1 = %AuctionBid{
        amount: 2.00,
        min_amount: 1.00,
        supplier_id: supplier1,
        auction_id: auction_id,
        vessel_fuel_id: vessel_fuel_id,
        time_entered: DateTime.utc_now(),
        original_time_entered: DateTime.utc_now()
      }

      supplier2_bid1 = %AuctionBid{
        amount: 2.00,
        min_amount: 1.50,
        supplier_id: supplier2,
        auction_id: auction_id,
        vessel_fuel_id: vessel_fuel_id,
        time_entered: DateTime.utc_now(),
        original_time_entered: DateTime.utc_now()
      }

      supplier2_bid2 = %AuctionBid{
        amount: 1.25,
        min_amount: nil,
        supplier_id: supplier2,
        auction_id: auction_id,
        vessel_fuel_id: vessel_fuel_id,
        time_entered: DateTime.utc_now(),
        original_time_entered: DateTime.utc_now()
      }

      initial_state = %ProductBidState{
        auction_id: auction_id,
        lowest_bids: [],
        minimum_bids: [supplier2_bid1, supplier1_bid1],
        active_bids: [],
        bids: []
      }

      {state, _events} = AuctionBidCalculator.process(initial_state, :open)
      {state, _events} = AuctionBidCalculator.process(state, supplier2_bid2, :open)
      {final_state, _events} = AuctionBidCalculator.process(state, :open)

      lowest_bids = Enum.map(final_state.lowest_bids, fn bid -> {bid.amount, bid.supplier_id} end)
      assert [{1.00, ^supplier1}, {1.25, ^supplier2} | _rest] = lowest_bids
    end

    test "after auction start with lower, unbeatable normal bid lowers all auto bids", %{
      auction: auction,
      vessel_fuel_id: vessel_fuel_id,
      supplier1: supplier1,
      supplier2: supplier2
    } do
      auction_id = auction.id

      supplier1_bid1 = %AuctionBid{
        amount: 2.00,
        min_amount: 1.00,
        supplier_id: supplier1,
        auction_id: auction_id,
        vessel_fuel_id: vessel_fuel_id,
        time_entered: DateTime.utc_now(),
        original_time_entered: DateTime.utc_now()
      }

      supplier2_bid1 = %AuctionBid{
        amount: 2.00,
        min_amount: 1.50,
        supplier_id: supplier2,
        auction_id: auction_id,
        vessel_fuel_id: vessel_fuel_id,
        time_entered: DateTime.utc_now(),
        original_time_entered: DateTime.utc_now()
      }

      supplier2_bid2 = %AuctionBid{
        amount: 0.75,
        min_amount: nil,
        supplier_id: supplier2,
        auction_id: auction_id,
        vessel_fuel_id: vessel_fuel_id,
        time_entered: DateTime.utc_now(),
        original_time_entered: DateTime.utc_now()
      }

      initial_state = %ProductBidState{
        auction_id: auction_id,
        lowest_bids: [],
        minimum_bids: [supplier2_bid1, supplier1_bid1],
        active_bids: [],
        bids: []
      }

      {state, _events} = AuctionBidCalculator.process(initial_state, :open)
      {state, _events} = AuctionBidCalculator.process(state, supplier2_bid2, :open)
      {final_state, _events} = AuctionBidCalculator.process(state, :open)

      lowest_bids = Enum.map(final_state.lowest_bids, fn bid -> {bid.amount, bid.supplier_id} end)
      assert [{0.75, ^supplier2}, {1.00, ^supplier1} | _rest] = lowest_bids
    end

    test "with multiple matching lowest bids", %{
      auction: auction,
      vessel_fuel_id: vessel_fuel_id,
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
        vessel_fuel_id: vessel_fuel_id,
        time_entered: DateTime.utc_now(),
        original_time_entered: DateTime.utc_now()
      }

      supplier2_bid1 = %AuctionBid{
        amount: nil,
        min_amount: 2.00,
        supplier_id: supplier2,
        auction_id: auction_id,
        vessel_fuel_id: vessel_fuel_id,
        time_entered: DateTime.utc_now(),
        original_time_entered: DateTime.utc_now()
      }

      supplier3_bid1 = %AuctionBid{
        amount: nil,
        min_amount: 3.50,
        supplier_id: supplier3,
        auction_id: auction_id,
        vessel_fuel_id: vessel_fuel_id,
        time_entered: DateTime.utc_now(),
        original_time_entered: DateTime.utc_now()
      }

      initial_state = %ProductBidState{
        auction_id: auction_id,
        lowest_bids: [],
        minimum_bids: [],
        active_bids: [],
        bids: []
      }

      {state, _events} = AuctionBidCalculator.process(initial_state, :open)
      {state, _events} = AuctionBidCalculator.process(state, supplier3_bid1, :open)
      {state, _events} = AuctionBidCalculator.process(state, supplier1_bid1, :open)
      {final_state, _events} = AuctionBidCalculator.process(state, supplier2_bid1, :open)

      lowest_bids = Enum.map(final_state.lowest_bids, fn bid -> {bid.amount, bid.supplier_id} end)
      assert [{2.00, ^supplier1}, {2.00, ^supplier2}, {3.50, ^supplier3}] = lowest_bids
    end

    test "with only multiple matching lowest bids", %{
      auction: auction,
      vessel_fuel_id: vessel_fuel_id,
      supplier1: supplier1,
      supplier2: supplier2
    } do
      auction_id = auction.id

      supplier1_bid1 = %AuctionBid{
        amount: 2.75,
        min_amount: 2.00,
        supplier_id: supplier1,
        auction_id: auction_id,
        vessel_fuel_id: vessel_fuel_id,
        time_entered: DateTime.utc_now(),
        original_time_entered: DateTime.utc_now()
      }

      supplier2_bid1 = %AuctionBid{
        amount: nil,
        min_amount: 2.00,
        supplier_id: supplier2,
        auction_id: auction_id,
        vessel_fuel_id: vessel_fuel_id,
        time_entered: DateTime.utc_now(),
        original_time_entered: DateTime.utc_now()
      }

      initial_state = %ProductBidState{
        auction_id: auction_id,
        lowest_bids: [],
        minimum_bids: [],
        active_bids: [],
        bids: []
      }

      {state, _events} = AuctionBidCalculator.process(initial_state, :open)
      {state, _events} = AuctionBidCalculator.process(state, supplier1_bid1, :open)
      {state, _events} = AuctionBidCalculator.process(state, supplier2_bid1, :open)

      lowest_bids = Enum.map(state.lowest_bids, fn bid -> {bid.amount, bid.supplier_id} end)
      assert [{2.00, ^supplier1}, {2.00, ^supplier2}] = lowest_bids
    end

    test "with differing lowest bids", %{
      auction: auction,
      vessel_fuel_id: vessel_fuel_id,
      supplier1: supplier1,
      supplier2: supplier2
    } do
      auction_id = auction.id

      supplier1_bid1 = %AuctionBid{
        amount: 500.00,
        supplier_id: supplier1,
        auction_id: auction_id,
        vessel_fuel_id: vessel_fuel_id,
        time_entered: DateTime.utc_now(),
        original_time_entered: DateTime.utc_now()
      }

      supplier2_bid1 = %AuctionBid{
        amount: nil,
        min_amount: 510.00,
        supplier_id: supplier2,
        auction_id: auction_id,
        vessel_fuel_id: vessel_fuel_id,
        time_entered: DateTime.utc_now(),
        original_time_entered: DateTime.utc_now()
      }

      initial_state = %ProductBidState{
        auction_id: auction_id,
        lowest_bids: [],
        minimum_bids: [],
        active_bids: [],
        bids: []
      }

      {state, _events} = AuctionBidCalculator.process(initial_state, :open)
      {state, _events} = AuctionBidCalculator.process(state, supplier1_bid1, :open)
      {state, _events} = AuctionBidCalculator.process(state, supplier2_bid1, :open)

      lowest_bids = Enum.map(state.lowest_bids, fn bid -> {bid.amount, bid.supplier_id} end)
      assert [{500.00, ^supplier1}, {510.00, ^supplier2}] = lowest_bids
    end

    test "revoking an auto bid invalidates that bid", %{
      auction: auction,
      vessel_fuel_id: vessel_fuel_id,
      supplier1: supplier1,
      supplier2: supplier2
    } do
      auction_id = auction.id

      supplier1_bid1 = %AuctionBid{
        amount: 2.75,
        min_amount: 2.00,
        supplier_id: supplier1,
        auction_id: auction_id,
        vessel_fuel_id: vessel_fuel_id,
        time_entered: DateTime.utc_now(),
        original_time_entered: DateTime.utc_now()
      }

      supplier2_bid1 = %AuctionBid{
        amount: nil,
        min_amount: 1.50,
        supplier_id: supplier2,
        auction_id: auction_id,
        vessel_fuel_id: vessel_fuel_id,
        time_entered: DateTime.utc_now(),
        original_time_entered: DateTime.utc_now()
      }

      initial_state = %ProductBidState{
        auction_id: auction_id,
        lowest_bids: [],
        minimum_bids: [],
        active_bids: [],
        bids: []
      }

      {state, _events} = AuctionBidCalculator.process(initial_state, :open)
      {state, _events} = AuctionBidCalculator.process(state, supplier1_bid1, :open)
      {state, _events} = AuctionBidCalculator.process(state, supplier2_bid1, :open)
      state = AuctionBidCalculator.revoke_supplier_bids(state, supplier1)

      refute Enum.any?(state.active_bids, fn bid -> bid.supplier_id == supplier1 end)
      refute Enum.any?(state.minimum_bids, fn bid -> bid.supplier_id == supplier1 end)
      refute Enum.any?(state.lowest_bids, fn bid -> bid.supplier_id == supplier1 end)
      assert Enum.any?(state.bids, fn bid -> bid.supplier_id == supplier1 end)
    end

    test "with no initial amount and existing lowest bid from same supplier maintains existing amount",
         %{
           auction: auction,
           vessel_fuel_id: vessel_fuel_id,
           supplier1: supplier1,
           supplier2: supplier2
         } do
      auction_id = auction.id

      supplier1_bid1 = %AuctionBid{
        amount: 2.00,
        min_amount: nil,
        supplier_id: supplier1,
        auction_id: auction_id,
        vessel_fuel_id: vessel_fuel_id,
        time_entered: DateTime.utc_now(),
        original_time_entered: DateTime.utc_now()
      }

      supplier2_bid1 = %AuctionBid{
        amount: 1.50,
        min_amount: nil,
        supplier_id: supplier2,
        auction_id: auction_id,
        vessel_fuel_id: vessel_fuel_id,
        time_entered: DateTime.utc_now(),
        original_time_entered: DateTime.utc_now()
      }

      supplier2_bid2 = %AuctionBid{
        amount: nil,
        min_amount: 1.00,
        supplier_id: supplier2,
        auction_id: auction_id,
        vessel_fuel_id: vessel_fuel_id,
        time_entered: DateTime.utc_now(),
        original_time_entered: DateTime.utc_now()
      }

      initial_state = %ProductBidState{
        auction_id: auction_id,
        lowest_bids: [supplier2_bid1, supplier1_bid1],
        minimum_bids: [],
        active_bids: [supplier2_bid1, supplier1_bid1],
        bids: [supplier2_bid1, supplier1_bid1]
      }

      {state, _events} = AuctionBidCalculator.process(initial_state, :open)
      {state, _events} = AuctionBidCalculator.process(state, supplier2_bid2, :open)
      {final_state, _events} = AuctionBidCalculator.process(state, :open)

      lowest_bids = Enum.map(final_state.lowest_bids, fn bid -> {bid.amount, bid.supplier_id} end)
      assert [{1.50, ^supplier2}, {2.00, ^supplier1}] = lowest_bids
    end

    test "with no initial amount and existing non-lowest bid from same supplier beats lowest existing amount",
         %{
           auction: auction,
           vessel_fuel_id: vessel_fuel_id,
           supplier1: supplier1,
           supplier2: supplier2
         } do
      auction_id = auction.id

      supplier1_bid1 = %AuctionBid{
        amount: 1.50,
        min_amount: nil,
        supplier_id: supplier1,
        auction_id: auction_id,
        vessel_fuel_id: vessel_fuel_id,
        time_entered: DateTime.utc_now(),
        original_time_entered: DateTime.utc_now()
      }

      supplier2_bid1 = %AuctionBid{
        amount: 2.00,
        min_amount: nil,
        supplier_id: supplier2,
        auction_id: auction_id,
        vessel_fuel_id: vessel_fuel_id,
        time_entered: DateTime.utc_now(),
        original_time_entered: DateTime.utc_now()
      }

      supplier2_bid2 = %AuctionBid{
        amount: nil,
        min_amount: 1.00,
        supplier_id: supplier2,
        auction_id: auction_id,
        vessel_fuel_id: vessel_fuel_id,
        time_entered: DateTime.utc_now(),
        original_time_entered: DateTime.utc_now()
      }

      initial_state = %ProductBidState{
        auction_id: auction_id,
        lowest_bids: [supplier2_bid1, supplier1_bid1],
        minimum_bids: [],
        active_bids: [supplier2_bid1, supplier1_bid1],
        bids: [supplier2_bid1, supplier1_bid1]
      }

      {state, _events} = AuctionBidCalculator.process(initial_state, :open)
      {state, _events} = AuctionBidCalculator.process(state, supplier2_bid2, :open)
      {final_state, _events} = AuctionBidCalculator.process(state, :open)

      lowest_bids = Enum.map(final_state.lowest_bids, fn bid -> {bid.amount, bid.supplier_id} end)
      assert [{1.25, ^supplier2}, {1.50, ^supplier1}] = lowest_bids
    end

    test "with revoked intermediate bid does not raise existing min bid amounts", %{
      auction: auction,
      vessel_fuel_id: vessel_fuel_id,
      supplier1: supplier1,
      supplier2: supplier2,
      supplier3: supplier3
    } do
      auction_id = auction.id

      supplier1_bid1 = %AuctionBid{
        amount: 5.00,
        min_amount: nil,
        supplier_id: supplier1,
        auction_id: auction_id,
        vessel_fuel_id: vessel_fuel_id,
        time_entered: DateTime.utc_now(),
        original_time_entered: DateTime.utc_now()
      }

      supplier2_bid1 = %AuctionBid{
        amount: 6.00,
        min_amount: 1.00,
        supplier_id: supplier2,
        auction_id: auction_id,
        vessel_fuel_id: vessel_fuel_id,
        time_entered: DateTime.utc_now(),
        original_time_entered: DateTime.utc_now()
      }

      supplier3_bid1 = %AuctionBid{
        amount: 3.00,
        min_amount: nil,
        supplier_id: supplier3,
        auction_id: auction_id,
        vessel_fuel_id: vessel_fuel_id,
        time_entered: DateTime.utc_now(),
        original_time_entered: DateTime.utc_now()
      }

      initial_state = %ProductBidState{
        auction_id: auction_id,
        lowest_bids: [],
        minimum_bids: [],
        active_bids: [],
        bids: []
      }

      {state, _events} = AuctionBidCalculator.process(initial_state, :open)
      {state, _events} = AuctionBidCalculator.process(state, supplier1_bid1, :open)
      {state, _events} = AuctionBidCalculator.process(state, supplier2_bid1, :open)
      {state, _events} = AuctionBidCalculator.process(state, supplier3_bid1, :open)
      {state, _events} = AuctionBidCalculator.process(state, :open)
      state = AuctionBidCalculator.revoke_supplier_bids(state, supplier3)
      {final_state, _events} = AuctionBidCalculator.process(state, :open)

      lowest_bids = Enum.map(final_state.lowest_bids, fn bid -> {bid.amount, bid.supplier_id} end)
      assert [{2.75, ^supplier2}, {5.00, ^supplier1}] = lowest_bids
    end
  end

  describe "events" do
    test "updated auto bids do fire bid events", %{
      auction: auction,
      vessel_fuel_id: vessel_fuel_id,
      supplier1: supplier1,
      supplier2: supplier2
    } do
      auction_id = auction.id

      supplier1_bid1 = %AuctionBid{
        amount: 2.00,
        min_amount: 1.75,
        supplier_id: supplier1,
        auction_id: auction_id,
        vessel_fuel_id: vessel_fuel_id,
        time_entered: DateTime.utc_now(),
        original_time_entered: DateTime.utc_now()
      }

      supplier2_bid1 = %AuctionBid{
        amount: 1.50,
        min_amount: 1.25,
        supplier_id: supplier2,
        auction_id: auction_id,
        vessel_fuel_id: vessel_fuel_id,
        time_entered: DateTime.utc_now(),
        original_time_entered: DateTime.utc_now()
      }

      supplier1_bid2 = %AuctionBid{
        amount: nil,
        min_amount: 1.00,
        supplier_id: supplier1,
        auction_id: auction_id,
        vessel_fuel_id: vessel_fuel_id,
        time_entered: DateTime.utc_now(),
        original_time_entered: DateTime.utc_now()
      }

      initial_state = %ProductBidState{
        auction_id: auction_id,
        lowest_bids: [],
        minimum_bids: [],
        active_bids: [],
        bids: []
      }

      {state, _} = AuctionBidCalculator.process(initial_state, supplier2_bid1, :open)
      {state, _} = AuctionBidCalculator.process(state, supplier1_bid1, :open)
      {state, _events} = AuctionBidCalculator.process(state, :open)
      {_state, events} = AuctionBidCalculator.process(state, supplier1_bid2, :open)

      assert [
               %AuctionEvent{
                 type: :auto_bid_triggered,
                 auction_id: auction_id,
                 data: %{
                   bid: %AuctionBid{
                     amount: 1.00,
                     vessel_fuel_id: ^vessel_fuel_id,
                     supplier_id: ^supplier1
                   }
                 }
               },
               %AuctionEvent{
                 type: :auto_bid_triggered,
                 auction_id: auction_id,
                 data: %{
                   bid: %AuctionBid{
                     amount: 1.25,
                     vessel_fuel_id: ^vessel_fuel_id,
                     supplier_id: ^supplier2
                   }
                 }
               }
             ] = events
    end

    test "unchanged auto bids do not fire bid events", %{
      auction: auction,
      vessel_fuel_id: vessel_fuel_id,
      supplier1: supplier1,
      supplier2: supplier2
    } do
      auction_id = auction.id

      supplier1_bid1 = %AuctionBid{
        amount: 2.50,
        min_amount: 2.00,
        supplier_id: supplier1,
        auction_id: auction_id,
        vessel_fuel_id: vessel_fuel_id,
        time_entered: DateTime.utc_now(),
        original_time_entered: DateTime.utc_now()
      }

      supplier2_bid1 = %AuctionBid{
        amount: 2.25,
        min_amount: 2.00,
        supplier_id: supplier2,
        auction_id: auction_id,
        vessel_fuel_id: vessel_fuel_id,
        time_entered: DateTime.utc_now(),
        original_time_entered: DateTime.utc_now()
      }

      supplier1_bid2 = %AuctionBid{
        amount: nil,
        min_amount: 1.75,
        supplier_id: supplier1,
        auction_id: auction_id,
        vessel_fuel_id: vessel_fuel_id,
        time_entered: DateTime.utc_now(),
        original_time_entered: DateTime.utc_now()
      }

      initial_state = %ProductBidState{
        auction_id: auction_id,
        lowest_bids: [],
        minimum_bids: [],
        active_bids: [],
        bids: []
      }

      {state, _} = AuctionBidCalculator.process(initial_state, supplier2_bid1, :open)
      {state, _} = AuctionBidCalculator.process(state, supplier1_bid1, :open)
      {state, _} = AuctionBidCalculator.process(state, :open)
      {_state, events} = AuctionBidCalculator.process(state, supplier1_bid2, :open)

      assert [
               %AuctionEvent{
                 type: :auto_bid_triggered,
                 auction_id: ^auction_id,
                 data: %{
                   bid: %AuctionBid{
                     amount: 1.75,
                     vessel_fuel_id: ^vessel_fuel_id,
                     supplier_id: ^supplier1
                   }
                 }
               }
             ] = events
    end
  end

  describe "pending auction" do
    test "does not lower auto bids", %{
      auction: auction,
      vessel_fuel_id: vessel_fuel_id,
      supplier1: supplier1,
      supplier2: supplier2
    } do
      auction_id = auction.id

      supplier1_bid1 = %AuctionBid{
        amount: 2.00,
        min_amount: 1.00,
        supplier_id: supplier1,
        auction_id: auction_id,
        vessel_fuel_id: vessel_fuel_id,
        time_entered: DateTime.utc_now(),
        original_time_entered: DateTime.utc_now()
      }

      supplier2_bid1 = %AuctionBid{
        amount: 2.00,
        min_amount: 1.50,
        supplier_id: supplier2,
        auction_id: auction_id,
        vessel_fuel_id: vessel_fuel_id,
        time_entered: DateTime.utc_now(),
        original_time_entered: DateTime.utc_now()
      }

      initial_state = %ProductBidState{
        auction_id: auction_id,
        lowest_bids: [],
        minimum_bids: [supplier2_bid1, supplier1_bid1],
        active_bids: [],
        bids: []
      }

      {state, _events} = AuctionBidCalculator.process(initial_state, :pending)

      assert initial_state == state
    end
  end
end
