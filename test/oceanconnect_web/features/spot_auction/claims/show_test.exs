defmodule OceanconnectWeb.Claims.ShowTest do
  use Oceanconnect.FeatureCase

  hound_session()

  alias Oceanconnect.AuctionShowPage
  alias Oceanconnect.Claims
  alias Oceanconnect.Auctions
  alias Oceanconnect.Deliveries

  setup do
    buyer_company = insert(:company)
    buyer = insert(:user, company: buyer_company)

    supplier_company = isnert(:company)
    supplier = insert(:user, company: supplier_company)

    auction =
      insert(
        :auction,
        buyer: buyer_company,
        suppliers: [supplier_company]
      )

    # claim = insert(:auction_claim, auction: auction)
    delivering_barge =
      insert(:auction_barge,
        auction: auction,
        supplier: supplier_company,
        approval_status: "APPROVED"
      )

    vessel_fuels = auction.auction_vessel_fuels

    fixture =
      close_auction!(auction)
      |> Auctions.create_fixtures_from_state()
      |> hd()

    claim =
      insert(
        :quantity_claim,
        type: "quantity",
        quantity_missing: 100,
        price_per_unit: 100,
        total_fuel_value: 10_000,
        additional_information: "Your fuel sucked!",
        auction: auction,
        fixture: fixture,
        receiving_vessel: fixture.vessel,
        delivered_fuel: fixture.vessel,
        supplier: fixture.supplier,
        buyer: buyer_company,
        notice_recipient_type: "supplier",
        notice_recipient: fixture.supplier
      )

    {:ok, _pid} = Oceanconnect.Notifications.NotificationsSupervisor.start_link()

    {:ok,
     %{
       buyer: buyer,
       supplier: supplier,
       claim: claim
     }}
  end

  describe "buyer" do
    test "can visit a quantity claim's show page and see claim details", %{
      buyer: buyer,
      claim: claim,
      auction: auction
    } do
      login_user(buyer)
      Claims.ShowPage.visit(auction.id, claim.id)
      assert Claims.ShowPage.is_current_path?(auction.id, claim.id)
      assert Claims.ShowPage.has_auction_details?(auction, claim.fixture)

      assert Claims.ShowPage.has_claim_type?(:quantity)
      assert Claims.ShowPage.has_receiving_vessel?(claim.receiving_vessel.name)
      assert Claims.ShowPage.has_delivered_fuel?(claim.delivered_fuel.name)
      assert Claims.ShowPage.has_delivering_barge?(claim.delivering_barge.name)

      assert Claims.ShowPage.has_claims_details?(claim)
      assert Claims.ShowPage.has_notice_recipient_type?(:supplier)
      assert Claims.ShowPage.has_last_correspondence_sent?(claim.last_correspondence)
    end
  end
end
