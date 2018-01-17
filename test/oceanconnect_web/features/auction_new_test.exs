defmodule Oceanconnect.AuctionNewTest do
  use Oceanconnect.FeatureCase, async: true
  alias Oceanconnect.AuctionNewPage

  hound_session()

  setup do
    company = insert(:company)
    user = insert(:user, company: company)
    login_user(user)
    buyer_vessels = insert_list(3, :vessel, company: company)
    insert(:vessel)
    {:ok, %{buyer_vessels: buyer_vessels}}
  end

  test "visting the new auction page" do
    AuctionNewPage.visit()

    assert AuctionNewPage.has_fields?([
      "additional_information",
      "anonymous_bidding",
      "auction_start",
      "duration",
      "eta",
      "etd",
      "fuel",
      "fuel_quantity",
      "po",
      "port",
      "vessel"
    ])
  end

  test "vessels dropdown list is filtered by buyer company", %{buyer_vessels: buyer_vessels} do
    AuctionNewPage.visit()

    buyer_vessel_mapset = Enum.map(buyer_vessels, fn(v) -> v.name end) |> MapSet.new
    assert MapSet.equal?(MapSet.new(AuctionNewPage.vessel_list()), buyer_vessel_mapset)
  end
end
