defmodule OceanconnectWeb.Claims.EditTest do
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
        :claim,
        type: "quantity",
        fixture: fixture,
        quantity_missing: 100,
        price_per_unit: 100,
        additional_information: "Your fuel sucked!",
        auction: auction,
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
    test "can visit a quantity claim's edit page through the auction show page", %{
      buyer: buyer,
      claim: claim,
      auction: auction
    } do
      claim = Deliveries.get_claim(claim.id)
      login_user(buyer)

      AuctionShowPage.visit(auction.id)
      :timer.sleep(200)
      AuctionShowPage.update_claim(claim.id)

      assert Claims.EditPage.is_current_path?(auction.id, claim.id)
      assert Claims.ShowPage.has_auction_details?(auction, claim.fixture)
    end

    test "can visit a quantity claim's edit page and post a new response", %{
      buyer: buyer,
      claim: claim,
      auction: auction
    } do
      claim = Deliveries.get_claim(claim.id)
      login_user(buyer)
      Claims.EditPage.visit(auction.id, claim.id)
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

      Claims.EditPage.place_notice(:supplier)
      Claims.EditPage.enter_response("Hey")
      Claims.EditPage.update_claim()

      assert Claims.EditPage.is_current_path?(auction.id, claim.id)
      %{responses: responses} = Deliveries.get_claim(claim.id)
      response = hd(responses)
      assert Claims.ShowPage.has_response?(response, "Hey", buyer)

      :timer.sleep(1_000)

      buyer_name = Oceanconnect.Accounts.User.full_name(buyer)

      assert_email_delivered_with(
        subject:
          "#{buyer_name} from #{claim.buyer.name} added a response to the claim against #{
            claim.supplier.name
          }"
      )
    end

    test "can close a claim", %{buyer: buyer, claim: claim, auction: auction} do
      login_user(buyer)
      Claims.EditPage.visit(auction.id, claim.id)
      assert Claims.EditPage.is_current_path?(auction.id, claim.id)

      Claims.EditPage.close_claim("Thanks, dog")
      Claims.EditPage.update_claim()
      claim = Deliveries.get_claim(claim.id)

      assert AuctionShowPage.is_current_path?(auction.id)
      AuctionShowPage.view_claim(claim.id)
      assert Claims.ShowPage.claim_resolved?()
      assert Claims.ShowPage.has_claim_resolution?("Thanks, dog")
    end
  end
end
