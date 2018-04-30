defmodule Oceanconnect.Auctions.AuctionCacheTest do
  use Oceanconnect.DataCase
  alias Oceanconnect.Auctions
  alias Oceanconnect.Auctions.{Auction, AuctionCache, AuctionSupervisor}

  setup do
    buyer_company = insert(:company)
    supplier = insert(:company, is_supplier: true)
    supplier_2 = insert(:company, is_supplier: true)
    auction = insert(:auction, buyer: buyer_company, suppliers: [supplier, supplier_2])

    {:ok, _pid} = AuctionSupervisor.start_link(auction)
    {:ok, %{auction: auction}}
  end

  test "reading from the cache", %{auction: auction} do
    assert ^auction = AuctionCache.read(auction.id)
  end

  test "updating the cache", %{auction: auction} do
    auction
    |> Auctions.update_auction!(%{po: "TEST STRING"}, nil)
    :timer.sleep(500)

    assert %Auction{po: "TEST STRING"} = AuctionCache.read(auction.id)
  end
end