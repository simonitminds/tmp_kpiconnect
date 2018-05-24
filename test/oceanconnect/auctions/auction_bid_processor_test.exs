defmodule Oceanconnect.Auctions.AuctionBidProcessorTest do
  use Oceanconnect.DataCase
  alias Oceanconnect.Auctions.AuctionBidProcessor
  alias Oceanconnect.Auctions.AuctionStore.AuctionState

  setup do
    supplier_company = insert(:company)
    supplier2_company = insert(:company)
    auction = insert(:auction, duration: 1_000, decision_duration: 1_000,
                      suppliers: [supplier_company, supplier2_company])

    {:ok, %{auction: auction, supplier1: supplier_company.id, supplier2: supplier2_company.id}}
  end

  describe "process_new_bid/2 when auction is pending" do
    test "auto_bid not triggered when a new lowest bid is placed", %{auction: auction, supplier1: supplier1, supplier2: supplier2} do
      bid = create_bid(10.00, 8.00, supplier1, auction)
      current_state = %AuctionState{
        auction_id: auction.id,
        status: :pending,
        lowest_bids: [bid],
        minimum_bids: [bid]
      }
      bid2 = create_bid(9.00, 8.00, supplier2, auction)
      {lowest_bid?, _supplier_first_bid?, updated_state} = AuctionBidProcessor.process_new_bid(bid2, current_state)

      assert lowest_bid?
      assert updated_state.lowest_bids == [bid2]
      assert updated_state.minimum_bids == [bid, bid2]
    end
  end

  describe "process_new_bid/2 when auction is open" do
    test "supplier can clear minimum bid", %{auction: auction, supplier1: supplier1} do
      bid = create_bid(10.00, 8.00, supplier1, auction)
      current_state = %AuctionState{
        auction_id: auction.id,
        status: :open,
        lowest_bids: [bid],
        minimum_bids: [bid]
      }
      new_bid = create_bid(9.50, nil, supplier1, auction)

      {lowest_bid?, _supplier_first_bid?, updated_state} = AuctionBidProcessor.process_new_bid(new_bid, current_state)

      assert lowest_bid?
      assert updated_state.lowest_bids == [new_bid]
      assert updated_state.minimum_bids == []
    end

    test "supplier can change minimum with no bid", %{auction: auction, supplier1: supplier1} do
      bid = create_bid(10.00, 8.00, supplier1, auction)
      current_state = %AuctionState{
        auction_id: auction.id,
        status: :open,
        lowest_bids: [bid],
        minimum_bids: [bid]
      }
      bid2 = create_bid(nil, 9.00, supplier1, auction)
      {_lowest_bid?, _supplier_first_bid?, updated_state} = AuctionBidProcessor.process_new_bid(bid2, current_state)

      assert updated_state.lowest_bids == [bid]
      assert updated_state.minimum_bids == [bid2]
    end

    test "auto_bid triggered when new minimum only match placed", %{auction: auction, supplier1: supplier1, supplier2: supplier2} do
      bid = create_bid(9.00, 8.00, supplier1, auction)
      current_state = %AuctionState{
        auction_id: auction.id,
        status: :open,
        lowest_bids: [bid],
        minimum_bids: [bid]
      }
      bid2 = create_bid(nil, 9.00, supplier2, auction)
      {lowest_bid?, _supplier_first_bid?, updated_state} = AuctionBidProcessor.process_new_bid(bid2, current_state)

      refute lowest_bid?
      assert Enum.map(updated_state.lowest_bids, &(&1.amount)) == [8.75]
      assert Enum.map(updated_state.lowest_bids, &(&1.supplier_id)) == [supplier1]
      assert updated_state.minimum_bids == [bid, bid2]
    end

    test "bid with only minimum can be added", %{auction: auction, supplier1: supplier1} do
      current_state = %AuctionState{
        auction_id: auction.id,
        status: :open,
        lowest_bids: [],
        minimum_bids: []
      }
      bid = create_bid(nil, 8.00, supplier1, auction)
      {lowest_bid?, _supplier_first_bid?, updated_state} = AuctionBidProcessor.process_new_bid(bid, current_state)

      assert lowest_bid?
      assert Enum.map(updated_state.lowest_bids, &(&1.amount)) == [8.00]
      assert updated_state.minimum_bids == [bid]
    end

    test "auto_bid loses when only losing minimum provided", %{auction: auction, supplier1: supplier1, supplier2: supplier2} do
      bid = create_bid(9.00, nil, supplier1, auction)
      current_state = %AuctionState{
        auction_id: auction.id,
        status: :open,
        lowest_bids: [bid],
        minimum_bids: []
      }
      bid2 = create_bid(nil, 10.00, supplier2, auction)
      {lowest_bid?, _supplier_first_bid?, updated_state} = AuctionBidProcessor.process_new_bid(bid2, current_state)

      refute lowest_bid?
      assert updated_state.lowest_bids == [bid]
      assert updated_state.minimum_bids == [bid2]
    end

    test "auto_bid matches when only minimum provided", %{auction: auction, supplier1: supplier1, supplier2: supplier2} do
      bid = create_bid(10.00, nil, supplier1, auction)
      current_state = %AuctionState{
        auction_id: auction.id,
        status: :open,
        lowest_bids: [bid],
        minimum_bids: []
      }
      bid2 = create_bid(nil, 10.00, supplier2, auction)
      {lowest_bid?, _supplier_first_bid?, updated_state} = AuctionBidProcessor.process_new_bid(bid2, current_state)

      refute lowest_bid?
      assert Enum.map(updated_state.lowest_bids, &(&1.amount)) == [10.00, 10.00]
      assert Enum.map(updated_state.lowest_bids, &(&1.supplier_id)) == [supplier1, supplier2]
      assert updated_state.minimum_bids == [bid2]
    end

    test "auto_bid wins when only minimum provided", %{auction: auction, supplier1: supplier1, supplier2: supplier2} do
      bid = create_bid(10.00, nil, supplier1, auction)
      current_state = %AuctionState{
        auction_id: auction.id,
        status: :open,
        lowest_bids: [bid],
        minimum_bids: []
      }
      bid2 = create_bid(nil, 8.00, supplier2, auction)
      {lowest_bid?, _supplier_first_bid?, updated_state} = AuctionBidProcessor.process_new_bid(bid2, current_state)

      assert lowest_bid?
      assert Enum.map(updated_state.lowest_bids, &(&1.amount)) == [9.75]
      assert Enum.map(updated_state.lowest_bids, &(&1.supplier_id)) == [supplier2]
      assert updated_state.minimum_bids == [bid2]
    end

    test "first bid is added to lowest_bids", %{auction: auction, supplier1: supplier1} do
      current_state = %AuctionState{
        auction_id: auction.id,
        status: :open,
        lowest_bids: [],
        minimum_bids: []
      }
      bid = create_bid(10.00, 8.00, supplier1, auction)
      {lowest_bid?, _supplier_first_bid?, updated_state} = AuctionBidProcessor.process_new_bid(bid, current_state)

      assert lowest_bid?
      assert updated_state.lowest_bids == [bid]
      assert updated_state.minimum_bids == [bid]
    end

    test "new higher bid with no minimum is not added", %{auction: auction, supplier1: supplier1, supplier2: supplier2} do
      bid = create_bid(10.00, nil, supplier1, auction)
      current_state = %AuctionState{
        auction_id: auction.id,
        status: :open,
        lowest_bids: [bid],
        minimum_bids: []
      }
      bid2 = create_bid(10.25, nil, supplier2, auction)
      {lowest_bid?, _supplier_first_bid?, updated_state} = AuctionBidProcessor.process_new_bid(bid2, current_state)

      refute lowest_bid?
      assert updated_state.lowest_bids == [bid]
    end

    test "new lowest bid replaces existing", %{auction: auction, supplier1: supplier1, supplier2: supplier2} do
      bid = create_bid(10.00, nil, supplier1, auction)
      current_state = %AuctionState{
        auction_id: auction.id,
        status: :open,
        lowest_bids: [bid],
        minimum_bids: []
      }
      bid2 = create_bid(9.50, nil, supplier2, auction)
      {lowest_bid?, _supplier_first_bid?, updated_state} = AuctionBidProcessor.process_new_bid(bid2, current_state)

      assert lowest_bid?
      assert updated_state.lowest_bids == [bid2]
    end

    test "new higher bid with matching minimum is appended", %{auction: auction, supplier1: supplier1, supplier2: supplier2} do
      bid = create_bid(10.00, nil, supplier1, auction)
      current_state = %AuctionState{
        auction_id: auction.id,
        status: :open,
        lowest_bids: [bid],
        minimum_bids: []
      }
      bid2 = create_bid(10.25, 10.00, supplier2, auction)
      {lowest_bid?, _supplier_first_bid?, updated_state} = AuctionBidProcessor.process_new_bid(bid2, current_state)

      refute lowest_bid?
      assert Enum.map(updated_state.lowest_bids, &(&1.amount)) == [10.00, 10.00]
      assert Enum.map(updated_state.lowest_bids, &(&1.supplier_id)) == [supplier1, supplier2]
    end

    test "new match to lowest bid with lower minimum replaces existing with auto_bid", %{auction: auction, supplier1: supplier1, supplier2: supplier2} do
      bid = create_bid(10.00, nil, supplier1, auction)
      current_state = %AuctionState{
        auction_id: auction.id,
        status: :open,
        lowest_bids: [bid],
        minimum_bids: []
      }
      bid2 = create_bid(10.00, 9.50, supplier2, auction)
      {lowest_bid?, _supplier_first_bid?, updated_state} = AuctionBidProcessor.process_new_bid(bid2, current_state)

      assert lowest_bid?
      assert Enum.map(updated_state.lowest_bids, &(&1.amount)) == [9.75]
      assert Enum.map(updated_state.lowest_bids, &(&1.supplier_id)) == [supplier2]
    end

    test "new match to lowest bid with no minimum is appended", %{auction: auction, supplier1: supplier1, supplier2: supplier2} do
      bid = create_bid(10.00, nil, supplier1, auction)
      current_state = %AuctionState{
        auction_id: auction.id,
        status: :open,
        lowest_bids: [bid],
        minimum_bids: []
      }
      bid2 = create_bid(10.00, nil, supplier2, auction)
      {lowest_bid?, _supplier_first_bid?, updated_state} = AuctionBidProcessor.process_new_bid(bid2, current_state)

      refute lowest_bid?
      assert Enum.map(updated_state.lowest_bids, &(&1.amount)) == [10.00, 10.00]
      assert Enum.map(updated_state.lowest_bids, &(&1.supplier_id)) == [supplier1, supplier2]
    end

    test "new lower bid with minimum replaces existing", %{auction: auction, supplier1: supplier1, supplier2: supplier2} do
      bid = create_bid(10.00, nil, supplier1, auction)
      current_state = %AuctionState{
        auction_id: auction.id,
        status: :open,
        lowest_bids: [bid],
        minimum_bids: []
      }
      bid2 = create_bid(9.75, 9.00, supplier2, auction)
      {lowest_bid?, _supplier_first_bid?, updated_state} = AuctionBidProcessor.process_new_bid(bid2, current_state)

      assert lowest_bid?
      assert updated_state.lowest_bids == [bid2]
      assert updated_state.minimum_bids == [bid2]
    end

    test "new lower bid beats minimum", %{auction: auction, supplier1: supplier1, supplier2: supplier2} do
      bid = create_bid(10.00, 9.50, supplier1, auction)
      current_state = %AuctionState{
        auction_id: auction.id,
        status: :open,
        lowest_bids: [bid],
        minimum_bids: [bid]
      }
      bid2 = create_bid(9.00, nil, supplier2, auction)

      {lowest_bid?, _supplier_first_bid?, updated_state} = AuctionBidProcessor.process_new_bid(bid2, current_state)

      assert lowest_bid?
      assert updated_state.lowest_bids == [bid2]
    end

    test "minimum bid threshold is matched and min_bid supplier wins with auto_bid", %{auction: auction, supplier1: supplier1, supplier2: supplier2} do
      bid = create_bid(10.00, 9.50, supplier1, auction)
      current_state = %AuctionState{
        auction_id: auction.id,
        status: :open,
        lowest_bids: [bid],
        minimum_bids: [bid]
      }
      bid2 = create_bid(9.50, nil, supplier2, auction)

      {lowest_bid?, _supplier_first_bid?, updated_state} = AuctionBidProcessor.process_new_bid(bid2, current_state)

      refute lowest_bid?
      assert Enum.map(updated_state.lowest_bids, &(&1.amount)) == [9.50, 9.50]
      assert Enum.map(updated_state.lowest_bids, &(&1.supplier_id)) == [supplier1, supplier2]
    end

    test "minimum bid threshold is matched and min_bid supplier wins", %{auction: auction, supplier1: supplier1, supplier2: supplier2} do
      bid = create_bid(9.50, 9.50, supplier1, auction)
      current_state = %AuctionState{
        auction_id: auction.id,
        status: :open,
        lowest_bids: [bid],
        minimum_bids: [bid]
      }
      bid2 = create_bid(9.50, nil, supplier2, auction)

      {lowest_bid?, _supplier_first_bid?, updated_state} = AuctionBidProcessor.process_new_bid(bid2, current_state)

      refute lowest_bid?
      assert Enum.map(updated_state.lowest_bids, &(&1.amount)) == [9.50, 9.50]
      assert Enum.map(updated_state.lowest_bids, &(&1.supplier_id)) == [supplier1, supplier2]
    end

    test "matching bid triggers auto_bid", %{auction: auction, supplier1: supplier1, supplier2: supplier2} do
      bid = create_bid(9.25, 8.00, supplier1, auction)
      current_state = %AuctionState{
        auction_id: auction.id,
        status: :open,
        lowest_bids: [bid],
        minimum_bids: [bid]
      }
      bid2 = create_bid(9.25, nil, supplier2, auction)

      {lowest_bid?, _supplier_first_bid?, updated_state} = AuctionBidProcessor.process_new_bid(bid2, current_state)

      refute lowest_bid?
      assert Enum.map(updated_state.lowest_bids, &(&1.amount)) == [9.00]
      assert Enum.map(updated_state.lowest_bids, &(&1.supplier_id)) == [supplier1]
    end

    test "lower bid triggers auto_bid", %{auction: auction, supplier1: supplier1, supplier2: supplier2} do
      bid = create_bid(9.25, 8.00, supplier1, auction)
      current_state = %AuctionState{
        auction_id: auction.id,
        status: :open,
        lowest_bids: [bid],
        minimum_bids: [bid]
      }
      bid2 = create_bid(9.00, nil, supplier2, auction)

      {lowest_bid?, _supplier_first_bid?, updated_state} = AuctionBidProcessor.process_new_bid(bid2, current_state)

      refute lowest_bid?
      assert Enum.map(updated_state.lowest_bids, &(&1.amount)) == [8.75]
      assert Enum.map(updated_state.lowest_bids, &(&1.supplier_id)) == [supplier1]
    end

    test "supplier bid doesn't compete against their own minimum", %{auction: auction, supplier1: supplier1, supplier2: supplier2} do
      bid = create_bid(9.25, 8.00, supplier1, auction)
      bid2 = create_bid(9.50, 9.50, supplier2, auction)
      current_state = %AuctionState{
        auction_id: auction.id,
        status: :open,
        lowest_bids: [bid],
        minimum_bids: [bid, bid2]
      }
      new_bid = create_bid(9.00, 8.00, supplier1, auction)

      {lowest_bid?, _supplier_first_bid?, updated_state} = AuctionBidProcessor.process_new_bid(new_bid, current_state)

      assert lowest_bid?
      assert updated_state.lowest_bids == [new_bid]
      assert updated_state.minimum_bids == [bid, bid2] # Ensures matching minimum bid doesn't replace original (chron order is maintained)
    end
  end

  describe "resolve_existing_bids/1" do
    test "empty minimum bid list is handled", %{auction: auction} do
      current_state = %AuctionState{
        auction_id: auction.id,
        status: :open,
        lowest_bids: [],
        minimum_bids: []
      }

      assert current_state == AuctionBidProcessor.resolve_existing_bids(current_state)
    end

    test "single minimum bid is resolved", %{auction: auction, supplier1: supplier1} do
      bid = create_bid(9.25, 8.00, supplier1, auction)
      current_state = %AuctionState{
        auction_id: auction.id,
        status: :open,
        lowest_bids: [bid],
        minimum_bids: [bid]
      }

      updated_state = AuctionBidProcessor.resolve_existing_bids(current_state)
      assert updated_state.lowest_bids == [bid]
    end

    test "minimum bid war with matching is resolved", %{auction: auction, supplier1: supplier1, supplier2: supplier2} do
      bid = create_bid(9.25, 8.00, supplier1, auction)
      bid2 = create_bid(9.00, 8.00, supplier2, auction)
      current_state = %AuctionState{
        auction_id: auction.id,
        status: :open,
        lowest_bids: [bid2],
        minimum_bids: [bid, bid2]
      }

      updated_state = AuctionBidProcessor.resolve_existing_bids(current_state)
      assert Enum.map(updated_state.lowest_bids, &(&1.amount)) == [8.00, 8.00]
      assert Enum.map(updated_state.lowest_bids, &(&1.supplier_id)) == [supplier1, supplier2]
    end

    test "minimum bid war is resolved", %{auction: auction, supplier1: supplier1, supplier2: supplier2} do
      bid = create_bid(9.25, 8.00, supplier1, auction)
      bid2 = create_bid(9.00, 8.50, supplier2, auction)
      current_state = %AuctionState{
        auction_id: auction.id,
        status: :open,
        lowest_bids: [bid2],
        minimum_bids: [bid, bid2]
      }

      updated_state = AuctionBidProcessor.resolve_existing_bids(current_state)
      assert Enum.map(updated_state.lowest_bids, &(&1.amount)) == [8.25]
      assert Enum.map(updated_state.lowest_bids, &(&1.supplier_id)) == [supplier1]
    end

    test "opening bid maintains winning position", %{auction: auction, supplier1: supplier1, supplier2: supplier2} do
      bid = create_bid(9.00, 8.00, supplier1, auction)
      bid2 = create_bid(9.50, 9.25, supplier2, auction)
      current_state = %AuctionState{
        auction_id: auction.id,
        status: :open,
        lowest_bids: [bid],
        minimum_bids: [bid, bid2]
      }

      updated_state = AuctionBidProcessor.resolve_existing_bids(current_state)
      assert updated_state.lowest_bids == [bid]
    end

    test "matched opening bid triggers minimum bid war", %{auction: auction, supplier1: supplier1, supplier2: supplier2} do
      bid = create_bid(9.50, 8.00, supplier1, auction)
      bid2 = create_bid(9.50, 8.75, supplier2, auction)
      current_state = %AuctionState{
        auction_id: auction.id,
        status: :open,
        lowest_bids: [bid2, bid],
        minimum_bids: [bid, bid2]
      }

      updated_state = AuctionBidProcessor.resolve_existing_bids(current_state)
      assert Enum.map(updated_state.lowest_bids, &(&1.amount)) == [8.50]
      assert Enum.map(updated_state.lowest_bids, &(&1.supplier_id)) == [supplier1]
    end

    test "auto_bid bid triggered on match to opening bid", %{auction: auction, supplier1: supplier1, supplier2: supplier2} do
      bid = create_bid(8.75, 8.00, supplier1, auction)
      bid2 = create_bid(9.50, 8.75, supplier2, auction)
      current_state = %AuctionState{
        auction_id: auction.id,
        status: :open,
        lowest_bids: [bid],
        minimum_bids: [bid, bid2]
      }

      updated_state = AuctionBidProcessor.resolve_existing_bids(current_state)
      assert Enum.map(updated_state.lowest_bids, &(&1.amount)) == [8.50]
      assert Enum.map(updated_state.lowest_bids, &(&1.supplier_id)) == [supplier1]
    end
  end
end
