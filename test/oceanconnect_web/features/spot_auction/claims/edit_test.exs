defmodule OceanconnectWeb.Claims.EditTest do
  use Oceanconnect.FeatureCase

  hound_session()

  alias Oceanconnect.AuctionShowPage
  alias Oceanconnect.Claims
  alias Oceanconnect.Auctions
  alias Oceanconnect.Deliveries

  setup do
    buyer_company = insert(:company)
    buyer = insert(:user, company: buyer_company)

    supplier_company = insert(:company)
    supplier = insert(:user, company: supplier_company)

    auction =
      insert(
        :auction,
        buyer: buyer_company,
        suppliers: [supplier_company]
      ) |> Auctions.fully_loaded()

    # claim = insert(:auction_claim, auction: auction)
    delivering_barge =
      insert(:auction_barge,
        auction: auction,
        supplier: supplier_company,
        approval_status: "APPROVED"
      )

    vessel_fuels = auction.auction_vessel_fuels

    {:ok, fixtures} =
      close_auction!(auction)
      |> Auctions.create_fixtures_from_state()

    fixture =
      hd(fixtures)
      |> Oceanconnect.Repo.preload([:vessel, :fuel, :supplier])

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
        delivered_fuel: fixture.fuel,
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
       claim: claim,
       auction: auction
     }}
  end

  describe "buyer" do
    test "can visit a quantity claim's edit page throught the auction show page", %{buyer: buyer, claim: claim, auction: auction} do
      claim = Deliveries.get_quantity_claim(claim.id)
      login_user(buyer)

      AuctionShowPage.visit(auction.id)
      AuctionShowPage.update_claim(claim.id)

      assert Claims.EditPage.is_current_path(auction.id, claim.id)
      assert Claims.ShowPage.has_auction_details?(auction, claim.fixture)
    end

    test "can visit a quantity claim's edit page and post a new response", %{
      buyer: buyer,
      claim: claim,
      auction: auction
    } do
      claim = Deliveries.get_quantity_claim(claim.id)
      login_user(buyer)
      Claims.EditPage.visit(auction.id, claim.id)
      assert Claims.EditPage.is_current_path?(auction.id, claim.id)
      assert Claims.ShowPage.has_auction_details?(auction, claim.fixture)

      assert Claims.ShowPage.has_claim_type?(:quantity)
      assert Claims.ShowPage.has_receiving_vessel?(claim.receiving_vessel.name)
      assert Claims.ShowPage.has_delivered_fuel?(claim.delivered_fuel.name)
      assert Claims.ShowPage.has_delivering_barge?(claim.delivering_barge.name)

      assert Claims.ShowPage.has_claims_details?(claim)
      assert Claims.ShowPage.has_notice_recipient_type?(:supplier)

      assert Claims.ShowPage.has_last_correspondence_sent?(
               :supplier,
               claim.supplier_last_correspondence
             )

      Claims.EditPage.place_notice(:supplier)
      Claims.EditPage.enter_response("Hey")
      Claims.EditPage.update_claim()

      assert Claims.EditPage.is_current_path?(auction.id, claim.id)
      %{responses: responses} = Deliveries.get_quantity_claim(claim.id)
      response = hd(responses)
      assert Claims.ShowPage.has_response?(response, "Hey", buyer)
    end

    test "can close a claim", %{buyer: buyer, claim: claim, auction: auction} do
      login_user(buyer)
      Claims.EditPage.visit(auction.id, claim.id)
      assert Claims.EditPage.is_current_path?(auction.id, claim.id)

      Claims.EditPage.close_claim("Thanks, dog")
      Claims.EditPage.update_claim()
      assert AuctionShowPage.is_current_path?(auction.id)
      assert AuctionShowPage.claim_resolved?(claim.id)
    end

    test "can visit a claim's show page after it has been closed", %{buyer: buyer, claim: claim, auction: auction} do
      login_user(buyer)

      Claims.EditPage.visit(auction.id, claim.id)
      assert Claims.EditPage.is_current_path?(auction.id, claim.id)
      Claims.EditPage.close_claim("Thanks, dog")
      Claims.EditPage.update_claim()

      assert AuctionShowPage.is_current_path?(auction.id)
      assert AuctionShowPage.claim_resolved?(claim.id)

      AuctionShowPage.view_claim(claim.id)
      claim = Deliveries.get_quantity_claim(claim.id)
      assert Claims.ShowPage.has_auction_details?(auction, claim.fixture)
      assert Claims.ShowPage.has_claim_resolution?("Thanks, dog")
    end
  end
end
