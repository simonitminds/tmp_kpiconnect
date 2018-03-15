defmodule Oceanconnect.Auctions.AuctionNotifierTest do
  use Oceanconnect.DataCase

  setup do
    supplier_company = insert(:company)
    auction = insert(:auction, suppliers: [supplier_company])
    {:ok, %{auction: auction}}
  end

  test "notifiy_participants", %{auction: _auction} do

  end
end
