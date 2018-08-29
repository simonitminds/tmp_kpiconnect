defmodule Oceanconnect.Auctions.AuctionPayloadTest do
  use Oceanconnect.DataCase

  alias Oceanconnect.Auctions
  alias Oceanconnect.Auctions.{AuctionPayload, AuctionSupervisor}

  describe "get_auction_payload!/1" do
    setup do
      buyer_company = insert(:company, name: "FooCompany")
      supplier = insert(:company, name: "BarCompany")
      supplier_2 = insert(:company, name: "BazCompany")

      auction =
        insert(:auction, buyer: buyer_company, suppliers: [supplier, supplier_2])
        |> Auctions.fully_loaded()

      {:ok, _pid} =
        start_supervised(
          {AuctionSupervisor,
           {auction, %{exclude_children: [:auction_reminder_timer, :auction_scheduler]}}}
        )

      Auctions.start_auction(auction)
      :timer.sleep(500)
      bid_params = %{"amount" => 1.25}

      {:ok,
       %{auction: auction, supplier: supplier, bid_params: bid_params, supplier_2: supplier_2}}
    end

    test "returns state payload for a buyer with supplier names in the bid_list", %{
      auction: auction,
      supplier: supplier,
      bid_params: bid_params
    } do
      Auctions.place_bid(auction, bid_params, supplier.id)

      payload =
        auction
        |> AuctionPayload.get_auction_payload!(auction.buyer_id)

      assert supplier.name in Enum.map(payload.bid_history, & &1.supplier)
      assert payload.status == :open
      assert supplier.name in Enum.map(payload.lowest_bids, & &1.supplier)
    end

    test "returns payload for a supplier", %{
      auction: auction,
      supplier: supplier,
      bid_params: bid_params = %{"amount" => amount},
      supplier_2: supplier_2
    } do
      Auctions.place_bid(auction, bid_params, supplier.id)
      Auctions.place_bid(auction, %{"amount" => 1.5}, supplier_2.id)

      payload =
        auction
        |> AuctionPayload.get_auction_payload!(supplier.id)

      assert payload.status == :open
      assert [%{amount: ^amount}, %{amount: 1.5}] = payload.lowest_bids
      assert length(payload.bid_history) == 1
      assert payload.bid_history |> hd == payload.lowest_bids |> hd
      assert [%{amount: ^amount}] = payload.bid_history

      lowest_bid = hd(payload.lowest_bids)
      refute Map.has_key?(lowest_bid, :supplier)
      assert Map.has_key?(lowest_bid, :supplier_id)
    end

    test "with an existing lowest bid", %{
      auction: auction,
      supplier: supplier,
      bid_params: bid_params = %{"amount" => amount},
      supplier_2: supplier_2
    } do
      Auctions.place_bid(auction, %{"amount" => 1.5}, supplier_2.id)

      payload =
        auction
        |> AuctionPayload.get_auction_payload!(supplier.id)

      assert [%{amount: 1.5}] = payload.lowest_bids
      assert length(payload.bid_history) == 0

      Auctions.place_bid(auction, bid_params, supplier.id)

      updated_payload =
        auction
        |> AuctionPayload.get_auction_payload!(supplier.id)

      assert updated_payload.status == :open
      assert [%{amount: ^amount}, %{amount: 1.5}] = updated_payload.lowest_bids
    end

    test "matching bids", %{
      auction: auction,
      supplier: supplier,
      bid_params: bid_params = %{"amount" => amount},
      supplier_2: supplier_2
    } do
      Auctions.place_bid(auction, %{"amount" => amount}, supplier_2.id)
      Auctions.place_bid(auction, bid_params, supplier.id)

      payload =
        auction
        |> AuctionPayload.get_auction_payload!(supplier.id)

      assert [%{amount: ^amount}, %{amount: ^amount}] = payload.lowest_bids

      buyer_payload =
        auction
        |> AuctionPayload.get_auction_payload!(auction.buyer_id)

      assert supplier.name in Enum.map(buyer_payload.bid_history, & &1.supplier)
      assert supplier_2.name in Enum.map(buyer_payload.bid_history, & &1.supplier)
      assert supplier_2.name in Enum.map(buyer_payload.lowest_bids, & &1.supplier)
      assert supplier.name in Enum.map(buyer_payload.lowest_bids, & &1.supplier)
    end

    test "auction goes to decision", %{
      auction: auction,
      bid_params: bid_params = %{"amount" => amount},
      supplier_2: supplier_2,
      supplier: supplier
    } do
      Auctions.place_bid(auction, %{"amount" => amount}, supplier_2.id)
      Auctions.place_bid(auction, bid_params, supplier.id)

      Auctions.end_auction(auction)

      payload =
        auction
        |> AuctionPayload.get_auction_payload!(supplier_2.id)

      assert [%{amount: ^amount}, %{amount: ^amount}] = payload.lowest_bids
    end

    test "anonymous_bidding", %{
      auction: auction,
      supplier: supplier,
      bid_params: bid_params = %{"amount" => amount},
      supplier_2: supplier_2
    } do
      auction =
        Oceanconnect.Repo.update!(Ecto.Changeset.change(auction, %{anonymous_bidding: true}))
        |> Auctions.create_supplier_aliases()
        |> Auctions.fully_loaded()

      Auctions.update_cache(auction)

      Auctions.place_bid(auction, %{"amount" => amount}, supplier_2.id)
      Auctions.place_bid(auction, bid_params, supplier.id)

      buyer_payload =
        auction
        |> AuctionPayload.get_auction_payload!(auction.buyer_id)

      refute supplier.name in Enum.map(buyer_payload.bid_history, & &1.supplier)
      refute supplier_2.name in Enum.map(buyer_payload.bid_history, & &1.supplier)
      refute supplier_2.name in Enum.map(buyer_payload.lowest_bids, & &1.supplier)

      assert Auctions.get_auction_supplier(auction.id, supplier.id).alias_name in Enum.map(
               buyer_payload.bid_history,
               & &1.supplier
             )

      assert Auctions.get_auction_supplier(auction.id, supplier_2.id).alias_name in Enum.map(
               buyer_payload.bid_history,
               & &1.supplier
             )

      assert Auctions.get_auction_supplier(auction.id, supplier_2.id).alias_name in Enum.map(
               buyer_payload.lowest_bids,
               & &1.supplier
             )
    end

    test "winning_bid added to payload", %{
      auction: auction,
      supplier: supplier,
      bid_params: bid_params = %{"amount" => amount},
      supplier_2: supplier_2
    } do
      Auctions.place_bid(auction, %{"amount" => amount}, supplier_2.id)
      bid = Auctions.place_bid(auction, bid_params, supplier.id)
      Auctions.end_auction(auction)
      Auctions.select_winning_bid(bid, "test")

      buyer_payload =
        auction
        |> AuctionPayload.get_auction_payload!(auction.buyer_id)

      assert bid.id == buyer_payload.winning_bid.id
      assert supplier.name == buyer_payload.winning_bid.supplier

      losing_supplier_payload =
        auction
        |> AuctionPayload.get_auction_payload!(supplier_2.id)

      assert bid.id == losing_supplier_payload.winning_bid.id
      refute Map.has_key?(losing_supplier_payload, :supplier_id)

      winning_supplier_payload =
        auction
        |> AuctionPayload.get_auction_payload!(supplier.id)

      assert bid.id == winning_supplier_payload.winning_bid.id
      refute Map.has_key?(winning_supplier_payload, :supplier_id)
    end

    test "includes submitted barges for supplier", %{auction: auction, supplier: supplier} do
      barge = insert(:barge, companies: [supplier])

      Auctions.submit_barge(auction, barge, supplier.id)

      payload =
        auction
        |> AuctionPayload.get_auction_payload!(supplier.id)

      assert length(payload.submitted_barges) == 1

      first = hd(payload.submitted_barges)
      assert first.barge_id == barge.id
    end

    test "includes submitted barges from supplier for buyer", %{
      auction: auction,
      supplier: supplier,
      supplier_2: supplier2
    } do
      barge = insert(:barge, companies: [supplier])
      barge2 = insert(:barge, companies: [supplier2])

      Auctions.submit_barge(auction, barge, supplier.id)
      Auctions.submit_barge(auction, barge2, supplier2.id)

      payload =
        auction
        |> AuctionPayload.get_auction_payload!(auction.buyer_id)

      assert length(payload.submitted_barges) == 2

      [first, second] = payload.submitted_barges
      assert first.barge_id == barge.id
      assert second.barge_id == barge2.id
    end
  end
end
