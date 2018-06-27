defmodule Oceanconnect.Auctions.AuctionBidCalculatorTest do
  use Oceanconnect.DataCase
  alias Oceanconnect.Auctions.AuctionStore.AuctionState
  alias Oceanconnect.Auctions.AuctionBidCalculator
  alias Oceanconnect.Auctions.AuctionBidList.AuctionBid

  setup do
    supplier_company = insert(:company)
    supplier2_company = insert(:company)

    auction =
      insert(
        :auction,
        duration: 1_000,
        decision_duration: 1_000,
        suppliers: [supplier_company, supplier2_company]
      )

    {:ok, %{auction: auction, supplier1: supplier_company.id, supplier2: supplier2_company.id}}
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

      assert %AuctionState{
               auction_id: ^auction_id,
               status: :open,
               winning_bid: nil,
               lowest_bids: [^new_bid],
               bids: [^new_bid],
               active_bids: [^new_bid],
               minimum_bids: [],
               inactive_bids: []
             } = AuctionBidCalculator.enter_bid(current_state, new_bid)
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

      assert %AuctionState{
               auction_id: ^auction_id,
               status: :open,
               winning_bid: nil,
               lowest_bids: [^new_bid, ^prev_bid],
               active_bids: [^new_bid, ^prev_bid],
               bids: [^new_bid, ^prev_bid],
               minimum_bids: []
             } = AuctionBidCalculator.enter_bid(current_state, new_bid)
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

      assert %AuctionState{
               auction_id: ^auction_id,
               status: :open,
               winning_bid: nil,
               lowest_bids: [^prev_bid, ^new_bid],
               bids: [^new_bid, ^prev_bid],
               minimum_bids: []
             } = AuctionBidCalculator.enter_bid(current_state, new_bid)
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

      assert %AuctionState{
               auction_id: ^auction_id,
               status: :open,
               winning_bid: nil,
               lowest_bids: [^prev_bid, ^new_bid],
               bids: [^new_bid, ^prev_bid],
               minimum_bids: []
             } = AuctionBidCalculator.enter_bid(current_state, new_bid)
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

      assert %AuctionState{
               auction_id: ^auction_id,
               status: :open,
               winning_bid: nil,
               lowest_bids: [^new_bid],
               active_bids: [^new_bid],
               bids: [^new_bid, ^updated_prev_bid],
               minimum_bids: [],
               inactive_bids: [^updated_prev_bid]
             } = AuctionBidCalculator.enter_bid(current_state, new_bid)
    end
  end

  describe "auto bidding" do
    test "entering a auto bid before the auction starts", %{
      auction: auction,
      supplier1: supplier1
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
        supplier_id: supplier1,
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

      current_state =
        AuctionBidCalculator.enter_bid(initial_state, supplier1_bid)
        |> AuctionBidCalculator.enter_bid(supplier2_bid)

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
      new_state = AuctionBidCalculator.process(state)

      assert [
               %AuctionBid{amount: 1.25, min_amount: 1.00, supplier_id: ^supplier1},
               %AuctionBid{amount: 1.50, min_amount: 1.50, supplier_id: ^supplier2}
             ] = new_state.lowest_bids

      inactive_bids =
        Enum.map(new_state.inactive_bids, fn bid -> {bid.amount, bid.supplier_id} end)

      assert [
               {1.5, supplier1},
               {1.75, supplier2},
               {1.75, supplier1},
               {2.0, supplier1},
               {2.0, supplier2}
             ] = inactive_bids
    end

    test "minimum bids get processed after auction start", %{
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

      next_state =
        %AuctionState{initial_state | status: :open}
        |> AuctionBidCalculator.process()
        |> AuctionBidCalculator.enter_auto_bid(supplier2_bid2)
        #|> IO.inspect()

      lowest_bids = Enum.map(next_state.lowest_bids, fn bid -> {bid.amount, bid.supplier_id} end)
      assert [{0.75, ^supplier2}, {1.00, ^supplier1} | _rest] = lowest_bids
    end
  end
end
