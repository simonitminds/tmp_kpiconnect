defmodule Oceanconnect.TermAuctionShowTest do
  use Oceanconnect.FeatureCase
  alias Oceanconnect.{AuctionShowPage, AuctionNewPage}
  alias Oceanconnect.Auctions

  hound_session()

  setup do
    auction = insert(:term_auction)

    fuel = auction.fuel
    buyer_company = auction.buyer
    [supplier_company] = auction.suppliers

    buyer = insert(:user, company: buyer_company)
    supplier = insert(:user, commpany: supplier_company)

    bid_params = %{
      amount: 1.25,
      comment: "Screw you!"
    }

    {:ok, _pid} =
      start_supervised(
        {Oceanconnect.Auctions.AuctionSupervisor,
         {auction, %{exclude_children: [:auction_reminder_timer]}}}
      )

    {:ok,
     %{
       auction: auction,
       buyer: buyer,
       buyer_company: buyer_company,
       supplier: supplier,
       bid_params: bid_params,
       fuel: fuel
     }}
  end
end
