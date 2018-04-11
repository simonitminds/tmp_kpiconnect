defmodule Oceanconnect.Auctions.AuctionPayloadTest do
  use Oceanconnect.DataCase

  alias Oceanconnect.Auctions
  alias Oceanconnect.Auctions.AuctionBidList.AuctionBid
  alias Oceanconnect.Auctions.{AuctionPayload, AuctionStore, AuctionsSupervisor, Command}

  describe "get_auction_payload!/1" do
    setup do
      buyer_company = insert(:company, name: "FooCompany")
      supplier = insert(:company, name: "BarCompany")
      supplier_2 = insert(:company, name: "BazCompany")
      auction = insert(:auction, buyer: buyer_company, suppliers: [supplier, supplier_2])
      start_supervised({Oceanconnect.Auctions.AuctionSupervisor, auction.id})
      start_supervised({Oceanconnect.Auctions.AuctionSupervisor, auction.id})

      auction
      |> Command.start_auction
      |> AuctionStore.process_command
      :timer.sleep(500)
      bid_params = %{"amount" => "1.25"}

      {:ok, %{auction: auction, supplier: supplier, bid_params: bid_params, supplier_2: supplier_2}}
    end

    test "returns state payload for a buyer with supplier names in the bid_list", %{auction: auction, supplier: supplier, bid_params: bid_params} do
      Auctions.place_bid(auction, bid_params, supplier.id)

      payload = auction
      |> AuctionPayload.get_auction_payload!(auction.buyer_id)

      assert supplier.name in Enum.map(payload.bid_list, &(&1.supplier))
      assert payload.state.status == :open
      assert supplier.name in Enum.map(payload.state.lowest_bids, &(&1.supplier))
    end

    test "returns payload for a supplier", %{auction: auction, supplier: supplier, bid_params: bid_params = %{"amount" => amount}, supplier_2: supplier_2} do
      Auctions.place_bid(auction, bid_params, supplier.id)
      Auctions.place_bid(auction, %{"amount" => "1.5"}, supplier_2.id)

      payload = auction
      |> AuctionPayload.get_auction_payload!(supplier.id)

      assert payload.state.status == :open
      assert [%AuctionBid{amount: ^amount}] = payload.state.lowest_bids
      assert payload.state.lowest_bids_position == 0
      assert length(payload.bid_list) == 1
      assert payload.bid_list |> hd |> Map.delete(:supplier_id) == payload.state.lowest_bids |> hd
      assert [%AuctionBid{amount: ^amount}] = payload.bid_list
    end

    test "with an existing lowest bid", %{auction: auction, supplier: supplier, bid_params: bid_params = %{"amount" => amount}, supplier_2: supplier_2} do
      Auctions.place_bid(auction, %{"amount" => "1.5"}, supplier_2.id)

      payload = auction
      |> AuctionPayload.get_auction_payload!(supplier.id)

      assert [%AuctionBid{amount: "1.5"}] = payload.state.lowest_bids
      assert payload.state.lowest_bids_position == nil
      assert length(payload.bid_list) == 0

      Auctions.place_bid(auction, bid_params, supplier.id)

      updated_payload = auction
      |> AuctionPayload.get_auction_payload!(supplier.id)

      assert updated_payload.state.status == :open
      assert [%AuctionBid{amount: ^amount}] = updated_payload.state.lowest_bids
      assert updated_payload.state.lowest_bids_position == 0
    end

    test "matching bids", %{auction: auction, supplier: supplier, bid_params: bid_params = %{"amount" => amount}, supplier_2: supplier_2} do
      Auctions.place_bid(auction, %{"amount" => amount}, supplier_2.id)
      Auctions.place_bid(auction, bid_params, supplier.id) 
      payload = auction
      |> AuctionPayload.get_auction_payload!(supplier.id)

      assert [%AuctionBid{amount: ^amount}] = payload.state.lowest_bids
      assert payload.state.lowest_bids_position == 1

      buyer_payload = auction
      |> AuctionPayload.get_auction_payload!(auction.buyer_id)

      assert supplier.name in Enum.map(buyer_payload.bid_list, &(&1.supplier))
      assert supplier_2.name in Enum.map(buyer_payload.bid_list, &(&1.supplier))
      assert supplier_2.name in Enum.map(buyer_payload.state.lowest_bids, &(&1.supplier))
      assert supplier.name in Enum.map(buyer_payload.state.lowest_bids, &(&1.supplier))
    end

    test "auction goes to decision", %{auction: auction, bid_params: bid_params = %{"amount" => amount}, supplier_2: supplier_2, supplier: supplier} do
      Auctions.place_bid(auction, %{"amount" => amount}, supplier_2.id)
      Auctions.place_bid(auction, bid_params, supplier.id)

      {:ok, auction_store_pid} = AuctionStore.find_pid(auction.id)
      GenServer.cast(auction_store_pid, {:end_auction, auction})

      payload = auction
      |> AuctionPayload.get_auction_payload!(supplier_2.id)

      assert [%AuctionBid{amount: ^amount}] = payload.state.lowest_bids
      assert payload.state.lowest_bids_position == 0
    end

    test "anonymous_bidding", %{auction: auction, supplier: supplier, bid_params: bid_params = %{"amount" => amount}, supplier_2: supplier_2}do
      auction = Oceanconnect.Repo.update!(Ecto.Changeset.change(auction, %{anonymous_bidding: true}))

      Auctions.place_bid(auction, %{"amount" => amount}, supplier_2.id)
      Auctions.place_bid(auction, bid_params, supplier.id)

      buyer_payload = auction
      |> AuctionPayload.get_auction_payload!(auction.buyer_id)

      refute supplier.name in Enum.map(buyer_payload.bid_list, &(&1.supplier))
      refute supplier_2.name in Enum.map(buyer_payload.bid_list, &(&1.supplier))
      refute supplier_2.name in Enum.map(buyer_payload.state.lowest_bids, &(&1.supplier))
      assert Auctions.get_auction_supplier(auction.id, supplier.id).alias_name in Enum.map(buyer_payload.bid_list, &(&1.supplier))
      assert Auctions.get_auction_supplier(auction.id, supplier_2.id).alias_name in Enum.map(buyer_payload.bid_list, &(&1.supplier))
      assert Auctions.get_auction_supplier(auction.id, supplier_2.id).alias_name in Enum.map(buyer_payload.state.lowest_bids, &(&1.supplier))
    end

    test "winning_bid added to payload", %{auction: auction, supplier: supplier, bid_params: bid_params = %{"amount" => amount}, supplier_2: supplier_2} do
      Auctions.place_bid(auction, %{"amount" => amount}, supplier_2.id)
      bid = Auctions.place_bid(auction, bid_params, supplier.id)

      auction
      |> Command.end_auction
      |> AuctionStore.process_command

      Auctions.select_winning_bid(bid, "test")

      buyer_payload = auction
      |> AuctionPayload.get_auction_payload!(auction.buyer_id)

      assert bid.id == buyer_payload.state.winning_bid.id
      assert supplier.name == buyer_payload.state.winning_bid.supplier

      losing_supplier_payload = auction
      |> AuctionPayload.get_auction_payload!(supplier_2.id)

      assert bid.id == losing_supplier_payload.state.winning_bid.id
      refute Map.has_key?(losing_supplier_payload, :supplier_id)
      assert false == losing_supplier_payload.state.winner

      winning_supplier_payload = auction
      |> AuctionPayload.get_auction_payload!(supplier.id)

      assert bid.id == winning_supplier_payload.state.winning_bid.id
      refute Map.has_key?(winning_supplier_payload, :supplier_id)
      assert true == winning_supplier_payload.state.winner
    end
  end
end
