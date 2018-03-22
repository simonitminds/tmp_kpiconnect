defmodule Oceanconnect.Auctions.AuctionBidListTest do
  use Oceanconnect.DataCase
  alias Oceanconnect.Auctions.{Command, AuctionBidList, AuctionStore}

  setup do
    supplier_company = insert(:company)
    supplier2_company = insert(:company)
    auction = insert(:auction, suppliers: [supplier_company, supplier2_company])
    bid = %{"amount" => "1.25"}
    |> Map.put("supplier_id", supplier_company.id)
    |> Map.put("id", UUID.uuid4(:hex))
    |> Map.put("time_entered", DateTime.utc_now())
    |> AuctionBidList.AuctionBid.from_params_to_auction_bid(auction)

    Oceanconnect.Auctions.AuctionsSupervisor.start_child(auction)
    Oceanconnect.Auctions.AuctionBidsSupervisor.start_child(auction.id)
    Oceanconnect.Auctions.start_auction(auction)
    {:ok, %{auction: auction, bid: bid, supplier2_company: supplier2_company}}
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

  test "entering a bid for auction", %{bid: bid} do
    assert AuctionBidList.get_bid_list(bid.auction_id) == []

    bid
    |> Command.enter_bid
    |> AuctionBidList.process_command

    actual_state = bid.auction_id
    |> AuctionBidList.get_bid_list
    |> hd

    assert Enum.all?(bid |> Map.from_struct, fn({k, v}) ->
      Map.fetch!(actual_state, k) == v
    end)
  end

  test "first bid by supplier in last 3 minutes extends duration", %{auction: auction, bid: bid, supplier2_company: supplier2_company} do
    bid
    |> Command.process_new_bid
    |> AuctionStore.process_command

    :timer.sleep(1_000)
    new_bid = bid
    |> Map.merge(%{id: UUID.uuid4(:hex), time_entered: DateTime.utc_now(), amount: "3.00", supplier_id: supplier2_company.id})

    new_bid
    |> Command.enter_bid
    |> AuctionBidList.process_command

    actual_state = AuctionStore.get_current_state(auction)

    assert [bid] == actual_state.winning_bids
    assert actual_state.time_remaining > 3 * 60_000 - 500
  end
end
