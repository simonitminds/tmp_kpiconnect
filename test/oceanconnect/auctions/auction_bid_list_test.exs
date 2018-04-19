defmodule Oceanconnect.Auctions.AuctionBidListTest do
  use Oceanconnect.DataCase
  alias Oceanconnect.Auctions
  alias Oceanconnect.Auctions.{AuctionBidList, AuctionPayload, AuctionSupervisor}

  setup do
    supplier_company = insert(:company)
    supplier2_company = insert(:company)
    auction = insert(:auction, suppliers: [supplier_company, supplier2_company])

    {:ok, _pid} = start_supervised({AuctionSupervisor, auction})
    Oceanconnect.Auctions.start_auction(auction)
    {:ok, %{auction: auction, supplier_id: supplier_company.id, supplier2_id: supplier2_company.id}}
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
end
