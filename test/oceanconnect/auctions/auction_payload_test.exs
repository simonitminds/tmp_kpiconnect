defmodule Oceanconnect.Auctions.AuctionPayloadTest do
  use Oceanconnect.DataCase

  alias Oceanconnect.Auctions
  alias Oceanconnect.Auctions.{Auction, Solution, AuctionPayload, AuctionSupervisor}
  alias Oceanconnect.Auctions.AuctionStore.{AuctionState, ProductBidState}

  # TODO: Re-write tests to use payload fixtures (buyer, supplier, observer, traded_bid)
  # and assert that the proper payload is returned based on the user_id provided. Can use
  # get_auction_payload!/3 to setup proper state for auction payload.

  setup do
    buyer_company = insert(:company, name: "FooCompany")
    supplier = insert(:company, name: "BarCompany")
    supplier_2 = insert(:company, name: "BazCompany")
    supplier_user = insert(:user, company: supplier)
    supplier_user2 = insert(:user, company: supplier_2)
    observer = insert(:user, is_observer: true)

    vessel_fuel = insert(:vessel_fuel)
    vessel_fuel_id = "#{vessel_fuel.id}"

    auction =
      insert(:auction,
        buyer: buyer_company,
        suppliers: [supplier, supplier_2],
        observers: [observer],
        auction_vessel_fuels: [vessel_fuel]
      )
      |> Auctions.fully_loaded()

    {:ok, _pid} =
      start_supervised(
        {AuctionSupervisor,
         {auction, %{exclude_children: [:auction_reminder_timer, :auction_scheduler]}}}
      )

    Auctions.start_auction(auction)
    :timer.sleep(500)

    {:ok,
     %{
       auction: auction,
       supplier: supplier,
       supplier_2: supplier_2,
       supplier_user: supplier_user,
       supplier_user2: supplier_user2,
       vessel_fuel_id: vessel_fuel_id,
       vessel_fuel: vessel_fuel
     }}
  end

  describe "get_auction_payload!/2" do
    test "returns state payload for a buyer with supplier names in the bid_list and no observers",
         %{
           auction: auction,
           supplier: supplier,
           vessel_fuel_id: vessel_fuel_id
         } do
      create_bid(1.25, nil, supplier.id, vessel_fuel_id, auction)
      |> Auctions.place_bid()

      auction_payload =
        %AuctionPayload{auction: returned_auction} =
        AuctionPayload.get_auction_payload!(auction, auction.buyer_id)

      payload = auction_payload.product_bids[vessel_fuel_id]

      assert supplier.name in Enum.map(payload.bid_history, & &1.supplier)
      assert supplier.name in Enum.map(payload.lowest_bids, & &1.supplier)
      assert auction_payload.status == :open

      refute Map.has_key?(returned_auction, :observers)
    end

    test "returns buyer payload that includes supplier coqs", %{
      auction: auction,
      supplier: supplier,
      supplier_2: supplier_2
    } do
      supplier_coq = create_auction_supplier_coq(auction, supplier)
      supplier_coq_2 = create_auction_supplier_coq(auction, supplier_2)

      auction_payload =
        auction
        |> Auctions.fully_loaded(true)
        |> AuctionPayload.get_auction_payload!(auction.buyer_id)

      assert MapSet.equal?(
               MapSet.new(Enum.map(auction_payload.auction.auction_supplier_coqs, & &1.id)),
               MapSet.new([supplier_coq.id, supplier_coq_2.id])
             )
    end

    test "returns supplier payload with only that supplier's coqs", %{
      auction: auction,
      supplier: supplier,
      supplier_2: supplier_2
    } do
      supplier_coq = create_auction_supplier_coq(auction, supplier)
      create_auction_supplier_coq(auction, supplier_2)

      auction_payload =
        auction
        |> Auctions.fully_loaded(true)
        |> AuctionPayload.get_auction_payload!(supplier.id)

      assert MapSet.equal?(
               MapSet.new(Enum.map(auction_payload.auction.auction_supplier_coqs, & &1.id)),
               MapSet.new([supplier_coq.id])
             )
    end

    test "returns correct amount in the payload for a supplier", %{
      auction: auction,
      supplier: supplier,
      supplier_2: supplier_2,
      vessel_fuel_id: vessel_fuel_id
    } do
      create_bid(1.25, nil, supplier.id, vessel_fuel_id, auction)
      |> Auctions.place_bid()

      create_bid(1.50, nil, supplier_2.id, vessel_fuel_id, auction)
      |> Auctions.place_bid()

      auction_payload = AuctionPayload.get_auction_payload!(auction, supplier.id)

      payload = auction_payload.product_bids[vessel_fuel_id]

      assert auction_payload.status == :open
      assert [%{amount: 1.25}, %{amount: 1.5}] = payload.lowest_bids
      assert length(payload.bid_history) == 1
      assert payload.bid_history |> hd == payload.lowest_bids |> hd
      assert [%{amount: 1.25}] = payload.bid_history

      lowest_bid = hd(payload.lowest_bids)
      refute Map.has_key?(lowest_bid, :supplier)
      assert Map.has_key?(lowest_bid, :supplier_id)
    end

    test "shows only own is_traded_bid information in lowest bids", %{
      auction: auction,
      supplier: supplier,
      supplier_2: supplier_2,
      vessel_fuel_id: vessel_fuel_id
    } do
      create_bid(1.25, nil, supplier.id, vessel_fuel_id, auction, true)
      |> Auctions.place_bid()

      create_bid(1.50, nil, supplier_2.id, vessel_fuel_id, auction, false)
      |> Auctions.place_bid()

      supplier1_payload = AuctionPayload.get_auction_payload!(auction, supplier.id)
      supplier1_product_payload = supplier1_payload.product_bids[vessel_fuel_id]

      assert [%{amount: 1.25, is_traded_bid: true}, %{amount: 1.5, is_traded_bid: false}] =
               supplier1_product_payload.lowest_bids

      supplier2_payload = AuctionPayload.get_auction_payload!(auction, supplier_2.id)
      supplier2_product_payload = supplier2_payload.product_bids[vessel_fuel_id]

      assert [%{amount: 1.25, is_traded_bid: false}, %{amount: 1.5, is_traded_bid: false}] =
               supplier2_product_payload.lowest_bids
    end

    test "contains is_traded_bid information in supplier's bid_history", %{
      auction: auction,
      supplier: supplier,
      vessel_fuel_id: vessel_fuel_id
    } do
      create_bid(1.25, nil, supplier.id, vessel_fuel_id, auction, true)
      |> Auctions.place_bid()

      auction_payload = AuctionPayload.get_auction_payload!(auction, supplier.id)
      payload = auction_payload.product_bids[vessel_fuel_id]

      assert [%{amount: 1.25, is_traded_bid: true}] = payload.bid_history
    end

    test "with an existing lowest bid", %{
      auction: auction,
      supplier: supplier,
      supplier_2: supplier_2,
      vessel_fuel_id: vessel_fuel_id
    } do
      create_bid(1.50, nil, supplier_2.id, vessel_fuel_id, auction, true)
      |> Auctions.place_bid()

      auction_payload = AuctionPayload.get_auction_payload!(auction, supplier.id)

      payload = auction_payload.product_bids[vessel_fuel_id]

      assert [%{amount: 1.5}] = payload.lowest_bids
      assert length(payload.bid_history) == 0

      create_bid(1.25, nil, supplier.id, vessel_fuel_id, auction, true)
      |> Auctions.place_bid()

      updated_auction_payload =
        auction
        |> AuctionPayload.get_auction_payload!(supplier.id)

      updated_payload = updated_auction_payload.product_bids[vessel_fuel_id]

      assert updated_auction_payload.status == :open
      assert [%{amount: 1.25}, %{amount: 1.5}] = updated_payload.lowest_bids
    end

    test "matching bids", %{
      auction: auction,
      supplier: supplier,
      supplier_2: supplier_2,
      vessel_fuel_id: vessel_fuel_id
    } do
      create_bid(1.25, nil, supplier_2.id, vessel_fuel_id, auction, true)
      |> Auctions.place_bid()

      create_bid(1.25, nil, supplier.id, vessel_fuel_id, auction, true)
      |> Auctions.place_bid()

      auction_payload = AuctionPayload.get_auction_payload!(auction, supplier.id)

      payload = auction_payload.product_bids[vessel_fuel_id]

      assert [%{amount: 1.25}, %{amount: 1.25}] = payload.lowest_bids

      buyer_auction_payload =
        auction
        |> AuctionPayload.get_auction_payload!(auction.buyer_id)

      buyer_payload = buyer_auction_payload.product_bids[vessel_fuel_id]

      assert supplier.name in Enum.map(buyer_payload.bid_history, & &1.supplier)
      assert supplier_2.name in Enum.map(buyer_payload.bid_history, & &1.supplier)
      assert supplier_2.name in Enum.map(buyer_payload.lowest_bids, & &1.supplier)
      assert supplier.name in Enum.map(buyer_payload.lowest_bids, & &1.supplier)
    end

    test "auction goes to decision", %{
      auction: auction,
      supplier: supplier,
      supplier_2: supplier_2,
      vessel_fuel_id: vessel_fuel_id
    } do
      create_bid(1.25, nil, supplier_2.id, vessel_fuel_id, auction)
      |> Auctions.place_bid()

      create_bid(1.25, nil, supplier.id, vessel_fuel_id, auction)
      |> Auctions.place_bid()

      Auctions.end_auction(auction)

      auction_payload = AuctionPayload.get_auction_payload!(auction, supplier_2.id)

      payload = auction_payload.product_bids[vessel_fuel_id]

      assert [%{amount: 1.25}, %{amount: 1.25}] = payload.lowest_bids
    end

    test "anonymous_bidding", %{
      auction: auction,
      supplier: supplier,
      supplier_2: supplier_2,
      vessel_fuel_id: vessel_fuel_id
    } do
      auction =
        Oceanconnect.Repo.update!(Ecto.Changeset.change(auction, %{anonymous_bidding: true}))
        |> Auctions.create_supplier_aliases()
        |> Auctions.fully_loaded()

      create_bid(1.25, nil, supplier_2.id, vessel_fuel_id, auction)
      |> Auctions.place_bid()

      create_bid(1.25, nil, supplier.id, vessel_fuel_id, auction)
      |> Auctions.place_bid()

      buyer_auction_payload = AuctionPayload.get_auction_payload!(auction, auction.buyer_id)

      buyer_payload = buyer_auction_payload.product_bids[vessel_fuel_id]

      refute supplier.name in Enum.map(buyer_payload.bid_history, & &1.supplier)
      refute supplier_2.name in Enum.map(buyer_payload.bid_history, & &1.supplier)
      refute supplier_2.name in Enum.map(buyer_payload.lowest_bids, & &1.supplier)

      assert Auctions.get_auction_supplier(auction, supplier.id).alias_name in Enum.map(
               buyer_payload.bid_history,
               & &1.supplier
             )

      assert Auctions.get_auction_supplier(auction, supplier_2.id).alias_name in Enum.map(
               buyer_payload.bid_history,
               & &1.supplier
             )

      assert Auctions.get_auction_supplier(auction, supplier_2.id).alias_name in Enum.map(
               buyer_payload.lowest_bids,
               & &1.supplier
             )
    end

    test "winning_solution added to payload", %{
      auction: auction = %Auction{id: auction_id},
      supplier: supplier,
      supplier_2: supplier_2,
      vessel_fuel_id: vessel_fuel_id
    } do
      _bid1 =
        create_bid(1.25, nil, supplier_2.id, vessel_fuel_id, auction)
        |> Auctions.place_bid()

      bid2 =
        create_bid(1.25, nil, supplier.id, vessel_fuel_id, auction)
        |> Auctions.place_bid()

      bid2_id = bid2.id

      Auctions.end_auction(auction)
      auction_state = Auctions.get_auction_state!(auction)

      Auctions.select_winning_solution(
        [bid2],
        auction_state.product_bids,
        auction,
        "you're winner",
        "Agent 9"
      )

      auction_payload = AuctionPayload.get_auction_payload!(auction, supplier_2.id)

      assert %Solution{
               auction_id: ^auction_id,
               bids: [
                 %{id: ^bid2_id, amount: 1.25, vessel_fuel_id: ^vessel_fuel_id}
               ],
               comment: "you're winner"
             } = auction_payload.solutions.winning_solution
    end

    test "includes submitted barges for supplier", %{auction: auction, supplier: supplier} do
      barge = insert(:barge, companies: [supplier])

      Auctions.submit_barge(auction, barge, supplier.id)

      auction_payload = AuctionPayload.get_auction_payload!(auction, supplier.id)

      assert length(auction_payload.submitted_barges) == 1

      first = hd(auction_payload.submitted_barges)
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

      auction_payload = AuctionPayload.get_auction_payload!(auction, auction.buyer_id)

      assert length(auction_payload.submitted_barges) == 2

      [first, second] = auction_payload.submitted_barges
      assert first.barge_id == barge.id
      assert second.barge_id == barge2.id
    end
  end

  describe "get_auction_payload!/3" do
    setup %{auction: auction, supplier: supplier, vessel_fuel_id: vessel_fuel_id} do
      bid = create_bid(1.25, nil, supplier.id, vessel_fuel_id, auction)

      state = %AuctionState{
        auction_id: auction.id,
        status: :open,
        product_bids: %{
          "#{vessel_fuel_id}" => %ProductBidState{
            auction_id: auction.id,
            vessel_fuel_id: vessel_fuel_id,
            active_bids: [bid],
            bids: [bid],
            lowest_bids: [bid]
          }
        }
      }

      {:ok, %{state: state}}
    end

    test "returns state payload for a buyer", %{
      auction: auction,
      supplier: supplier,
      vessel_fuel_id: vessel_fuel_id,
      state: state
    } do
      auction_payload = AuctionPayload.get_auction_payload!(auction, auction.buyer_id, state)
      payload = auction_payload.product_bids[vessel_fuel_id]

      assert supplier.name in Enum.map(payload.bid_history, & &1.supplier)
      assert supplier.name in Enum.map(payload.lowest_bids, & &1.supplier)
      assert auction_payload.status == :open
    end
  end
end
