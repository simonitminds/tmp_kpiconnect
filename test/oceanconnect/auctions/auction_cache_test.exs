defmodule Oceanconnect.Auctions.AuctionCacheTest do
  use Oceanconnect.DataCase
  alias Oceanconnect.Auctions
  alias Oceanconnect.Auctions.{Auction, AuctionCache, AuctionSupervisor}

  setup do
    buyer_company = insert(:company, name: "FooCompany")
    supplier = insert(:company, name: "BarCompany")
    supplier_2 = insert(:company, name: "BazCompany")
    auction = insert(:auction, buyer: buyer_company, suppliers: [supplier, supplier_2])

    AuctionSupervisor.start_link(auction)
    {:ok, %{auction: auction}}
  end

  test "reading from the cache", %{auction: auction} do
    assert ^auction = AuctionCache.read(auction.id)
  end

  test "updating the cache", %{auction: auction} do
    auction
    |> Auctions.update_auction!(%{po: "TEST STRING"})
    |> AuctionCache.update_cache()

    assert %Auction{po: "TEST STRING"} = AuctionCache.read(auction.id)
  end
end
