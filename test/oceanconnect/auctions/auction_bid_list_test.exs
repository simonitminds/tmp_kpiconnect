defmodule Oceanconnect.Auctions.AuctionBidListTest do
  use Oceanconnect.DataCase
  alias Oceanconnect.Utilities
  alias Oceanconnect.Auctions.{Command, AuctionBidList}
  alias Oceanconnect.Auctions.AuctionBidList.{AuctionBid}

  setup do
    supplier_company = insert(:company)
    supplier = insert(:user, company: supplier_company)
    auction = insert(:auction, suppliers: [supplier_company])
    bid_params = %{
      auction_id: auction.id,
      amount: 1.25,
      fuel_quantity: auction.fuel_quantity,
      supplier_id: supplier.id
    }
    Oceanconnect.Auctions.AuctionBidsSupervisor.start_child(auction.id)
    {:ok, %{auction: auction, bid_params: bid_params}}
  end

  test "starting auction_bid_list for auction", %{bid_params: bid_params} do
    assert AuctionBidList.get_bid_list(bid_params.auction_id) == []

    %AuctionBid{auction_id: nil, amount: nil, supplier_id: nil}
    |> Map.merge(bid_params)
    |> Command.enter_bid
    |> AuctionBidList.process_command

    actual_state = bid_params.auction_id
    |> AuctionBidList.get_bid_list
    |> hd

    assert Enum.all?(bid_params, fn({k, v}) ->
      Map.fetch!(actual_state, k) == v
    end)
  end

  test "auction is supervised", %{auction: auction} do
    {:ok, pid} = AuctionBidList.find_pid(auction.id)
    assert Process.alive?(pid)

    Process.exit(pid, :shutdown)

    refute Process.alive?(pid)
    :timer.sleep(500)

    {:ok, new_pid} = AuctionBidList.find_pid(auction.id)
    assert Process.alive?(new_pid)
  end
end
