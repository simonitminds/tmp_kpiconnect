defmodule Oceanconnect.Auctions.AuctionCacheTest do
  use Oceanconnect.DataCase
  alias Oceanconnect.Auctions
  alias Oceanconnect.Auctions.{Auction, AuctionCache, AuctionSupervisor}

  setup do
    buyer_company = insert(:company)
    supplier = insert(:company, is_supplier: true)
    supplier_2 = insert(:company, is_supplier: true)

    auction =
      insert(:auction, buyer: buyer_company, suppliers: [supplier, supplier_2])
      |> Auctions.fully_loaded()

    {:ok, _pid} =
      start_supervised(
        {AuctionSupervisor,
         {auction,
          %{
            exclude_children: [
              :auction_reminder_timer,
              :auction_event_handler,
              :auction_scheduler
            ]
          }}}
      )

    {:ok, %{auction: auction}}
  end

  test "reading from the cache", %{auction: auction} do
    assert ^auction = AuctionCache.read(auction.id)
  end

  test "updating the cache", %{auction: auction} do
    auction
    |> Auctions.update_auction!(%{po: "TEST STRING"}, nil)

    :timer.sleep(200)

    assert %Auction{po: "TEST STRING"} = AuctionCache.read(auction.id)
  end
end
