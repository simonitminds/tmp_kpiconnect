defmodule Oceanconnect.AuctionEditTest do
  use Oceanconnect.FeatureCase
  alias Oceanconnect.AuctionEditPage

  hound_session()

  setup do
    buyer_company = insert(:company)
    buyer = insert(:user, company: buyer_company)
    login_user(buyer)
    insert_list(2, :vessel, company: buyer_company)
    {:ok, %{auction: insert(:auction, buyer: buyer_company)}}
  end

  test "visting the edit auction page", %{auction: auction} do
    AuctionEditPage.visit(auction.id)

    assert AuctionEditPage.has_fields?([
      "additional_information",
      "anonymous_bidding",
      "auction_start",
      "duration",
      "decision_duration",
      "eta",
      "etd",
      "fuel_id",
      "fuel_quantity",
      "po",
      "port_id",
      "vessel_id"
    ])
  end
end
