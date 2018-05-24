defmodule Oceanconnect.Auctions.AuctionBidListTest do
  use Oceanconnect.DataCase
  alias Oceanconnect.Auctions
  alias Oceanconnect.Auctions.{AuctionBidList, AuctionPayload, AuctionSupervisor}

  setup do
    supplier_company = insert(:company)
    supplier2_company = insert(:company)
    auction = insert(:auction, suppliers: [supplier_company, supplier2_company])

    {:ok, _pid} = start_supervised({AuctionSupervisor, {auction, %{exclude_children: [:auction_event_handler, :auction_scheduler]}}})
    {:ok, %{auction: auction, supplier_company: supplier_company, supplier_id: supplier_company.id, supplier2_id: supplier2_company.id}}
  end

  test "ensure auto_bids are placed at auction start", %{auction: auction, supplier_company: supplier_company, supplier2_id: supplier2_id} do
    Auctions.place_bid(auction, %{"amount" => 9.50, "min_amount" => 8.00}, supplier_company.id)
    Auctions.place_bid(auction, %{"amount" => 9.25, "min_amount" => 8.50}, supplier2_id)
    Auctions.start_auction(auction)

    actual_payload = AuctionPayload.get_auction_payload!(auction, auction.buyer_id)

    assert hd(actual_payload.state.lowest_bids).amount == 8.25
    assert hd(actual_payload.state.lowest_bids).supplier == supplier_company.name
    assert Enum.map(actual_payload.bid_list, &(&1.amount)) == [8.50, 8.25, 9.25, 9.50]
  end

  describe "started auction" do
    setup %{auction: auction} do
      Auctions.start_auction(auction)
      :ok
    end

    test "entering a bid for auction", %{auction: auction, supplier_id: supplier_id} do
      assert AuctionBidList.get_bid_list(auction.id) == []

      bid = Auctions.place_bid(auction, %{"amount" => 1.25}, supplier_id)

      :timer.sleep(500)
      actual_state = auction.id
      |> AuctionBidList.get_bid_list
      |> hd

      assert Enum.all?(bid |> Map.from_struct, fn({k, v}) ->
        Map.fetch!(actual_state, k) == v
      end)
    end

    test "first bid by supplier in last 3 minutes extends duration", %{auction: auction, supplier_id: supplier_id, supplier2_id: supplier2_id} do
      bid = Auctions.place_bid(auction, %{"amount" => 1.25}, supplier_id)
      Auctions.place_bid(auction, %{"amount" => 3.00}, supplier2_id)

      actual_payload = AuctionPayload.get_auction_payload!(auction, supplier2_id)

      assert [bid |> Map.delete(:supplier_id)] == actual_payload.state.lowest_bids
      assert actual_payload.time_remaining > 3 * 60_000 - 500
    end

    test "supplier can change minimum with no bid to match their lowest", %{auction: auction, supplier_id: supplier_id} do
      bid = Auctions.place_bid(auction, %{"amount" => 10.00, "min_amount" => 8.00}, supplier_id)
      bid2 = Auctions.place_bid(auction, %{"amount" => nil, "min_amount" => 10.00}, supplier_id)

      actual_payload = AuctionPayload.get_auction_payload!(auction, supplier_id)

      assert [bid |> Map.delete(:supplier_id)] == actual_payload.state.lowest_bids
      assert actual_payload.bid_list == [bid2, bid]
    end

    test "supplier can raise minimum with no bid above their lowest", %{auction: auction, supplier_id: supplier_id} do
      bid = Auctions.place_bid(auction, %{"amount" => 10.00, "min_amount" => 8.00}, supplier_id)
      bid2 = Auctions.place_bid(auction, %{"amount" => nil, "min_amount" => 11.00}, supplier_id)

      actual_payload = AuctionPayload.get_auction_payload!(auction, supplier_id)

      assert [bid |> Map.delete(:supplier_id)] == actual_payload.state.lowest_bids
      assert actual_payload.bid_list == [bid2, bid]
    end

    test "losing auto_bid placed", %{auction: auction, supplier_company: supplier_company, supplier2_id: supplier2_id} do
      Auctions.place_bid(auction, %{"amount" => 8.50, "min_amount" => 8.00}, supplier_company.id)
      Auctions.place_bid(auction, %{"amount" => nil, "min_amount" => 9.00}, supplier2_id)

      actual_payload = AuctionPayload.get_auction_payload!(auction, auction.buyer_id)

      assert hd(actual_payload.state.lowest_bids).amount == 8.50
      assert hd(actual_payload.state.lowest_bids).supplier == supplier_company.name
      assert Enum.map(actual_payload.bid_list, &(&1.amount)) == [9.00, nil, 8.50]
    end
  end
end
