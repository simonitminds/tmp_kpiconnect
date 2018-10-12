defmodule Oceanconnect.AuctionEditTest do
  use Oceanconnect.FeatureCase
  alias Oceanconnect.AuctionEditPage

  hound_session()

  setup do
    buyer_company = insert(:company, is_supplier: true, credit_margin_amount: 5.0)
    buyer = insert(:user, company: buyer_company)
    login_user(buyer)
    insert_list(2, :vessel, company: buyer_company)
    {:ok, %{auction: insert(:auction, buyer: buyer_company, is_traded_bid_allowed: true)}}
  end

  test "visting the edit auction page", %{auction: auction} do
    AuctionEditPage.visit(auction.id)

    assert AuctionEditPage.has_fields?([
      "additional_information",
      "anonymous_bidding",
      "credit_margin_amount",
      "decision_duration",
      "duration",
      "eta",
      "etd",
      "is_traded_bid_allowed",
      "po",
      "port_id",
      "scheduled_start",
      "select-fuel",
      "select-port",
      "select-vessel"
    ])
  end
end
