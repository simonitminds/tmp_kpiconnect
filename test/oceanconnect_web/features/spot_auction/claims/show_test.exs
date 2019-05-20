defmodule OceanconnectWeb.Claims.ShowTest do
  use Oceanconnect.FeatureCase
  use Bamboo.Test, shared: true

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
      )
      |> Auctions.fully_loaded()

    # claim = insert(:auction_claim, auction: auction)
    _delivering_barge =
      insert(:auction_barge,
        auction: auction,
        supplier: supplier_company,
        approval_status: "APPROVED"
      )

    _vessel_fuels = auction.auction_vessel_fuels

    {:ok, fixtures} =
      close_auction!(auction)
      |> Auctions.create_fixtures_from_state()

    fixture =
      hd(fixtures)
      |> Oceanconnect.Repo.preload([:vessel, :fuel, :supplier])

    claim =
      insert(
        :claim,
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
       buyer_company: buyer_company,
       supplier: supplier,
       supplier_company: supplier_company,
       claim: claim,
       auction: auction
     }}
  end

  describe "buyer" do
    test "can visit cannot visit a closed quantity claim's show page", %{
      buyer: buyer,
      claim: claim,
      auction: auction
    } do
      claim = Deliveries.get_claim(claim.id)
      login_user(buyer)
      Claims.ShowPage.visit(auction.id, claim.id)
      assert Claims.EditPage.is_current_path?(auction.id, claim.id)
      assert Claims.ShowPage.has_auction_details?(auction, claim.fixture)

      assert Claims.ShowPage.has_claim_type?(:quantity)
      assert Claims.ShowPage.has_receiving_vessel?(claim.receiving_vessel.name)
      assert Claims.ShowPage.has_delivered_fuel?(claim.delivered_fuel.name)
      assert Claims.ShowPage.has_delivering_barge?(claim.delivering_barge.name)

      assert Claims.ShowPage.has_claims_details?(claim, :quantity)
      assert Claims.ShowPage.has_notice_recipient_type?(:supplier)

      assert Claims.ShowPage.has_last_correspondence_sent?(
               :supplier,
               claim.supplier_last_correspondence
             )
    end

    test "can visit a claim's show page after it is closed", %{
      buyer: buyer,
      claim: claim,
      auction: auction
    } do
      claim = Deliveries.get_claim(claim.id)
      login_user(buyer)
      Claims.EditPage.visit(auction.id, claim.id)
      assert Claims.EditPage.is_current_path?(auction.id, claim.id)
      Claims.EditPage.close_claim("Thanks, dog")
      Claims.EditPage.update_claim()

      assert AuctionShowPage.is_current_path?(auction.id)
      :timer.sleep(500)
      AuctionShowPage.view_claim(claim.id)
      assert Claims.ShowPage.is_current_path?(auction.id, claim.id)
      assert Claims.ShowPage.claim_resolved?()
      assert Claims.ShowPage.has_claim_resolution?("Thanks, dog")
    end
  end

  describe "supplier" do
    test "can visit claim show page through auction show page and post a new response", %{
      buyer_company: buyer_company,
      supplier: supplier,
      supplier_company: supplier_company,
      auction: auction,
      claim: claim
    } do
      login_user(supplier)
      AuctionShowPage.visit(auction.id)
      assert AuctionShowPage.is_current_path?(auction.id)
      assert AuctionShowPage.auction_status() == "CLOSED"
      Hound.Helpers.Screenshot.take_screenshot()
      AuctionShowPage.view_claim(claim.id)
      assert Claims.ShowPage.is_current_path?(auction.id, claim.id)
      Claims.EditPage.enter_response("I'm sorry our fuel sucked so much")
      Claims.ShowPage.add_response()

      %{responses: responses} = Deliveries.get_claim(claim.id)
      response = hd(responses)

      assert Claims.ShowPage.has_response?(
               response,
               "I'm sorry our fuel sucked so much",
               supplier
             )

      :timer.sleep(1_000)
      supplier_name = Oceanconnect.Accounts.User.full_name(supplier)

      assert_email_delivered_with(
        subject:
          "#{supplier_name} from #{supplier_company.name} responded to the claim made by #{
            buyer_company.name
          }"
      )
    end
  end
end
