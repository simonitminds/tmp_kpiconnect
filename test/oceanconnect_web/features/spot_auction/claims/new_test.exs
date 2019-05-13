defmodule OceanconnectWeb.SpotAuction.Claims.NewTest do
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

    supplier_company = insert(:company, is_supplier: true)
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

    auction_state = close_auction!(auction)
    {:ok, auction_fixtures} = Auctions.create_fixtures_from_state(auction_state)

    auction_fixtures =
      auction_fixtures
      |> Oceanconnect.Repo.preload([:supplier, :vessel, :fuel])

    {:ok, _pid} = Oceanconnect.Notifications.NotificationsSupervisor.start_link()

    {:ok,
     %{
       buyer: buyer,
       supplier: supplier,
       supplier_company: supplier_company,
       auction: auction,
       vessel_fuels: vessel_fuels,
       delivering_barge: delivering_barge.barge,
       fixture: hd(auction_fixtures)
     }}
  end

  describe "buyer" do
    test "if no claims have been placed none are shown and a message displays saying none are placed",
         %{
           buyer: buyer,
           auction: auction
         } do
      login_user(buyer)
      AuctionShowPage.visit(auction.id)
      :timer.sleep(200)
      assert AuctionShowPage.has_content?("No activities have been logged for this auction.")
    end

    test "can visit auction show page and place a claim", %{buyer: buyer, auction: auction} do
      login_user(buyer)
      AuctionShowPage.visit(auction.id)
      assert AuctionShowPage.is_current_path?(auction.id)
      assert AuctionShowPage.auction_status() == "CLOSED"

      assert AuctionShowPage.has_place_claim_button?()
      AuctionShowPage.place_claim()
      assert Claims.NewPage.is_current_path?(auction.id)
    end

    test "can place a new quantity claim", %{
      buyer: buyer,
      auction: auction,
      fixture: fixture,
      delivering_barge: delivering_barge
    } do
      login_user(buyer)
      Claims.NewPage.visit(auction.id)
      assert Claims.NewPage.is_current_path?(auction.id)
      Claims.NewPage.select_claim_type(:quantity)
      Claims.NewPage.select_fixture(fixture.id, :quantity)

      Claims.NewPage.enter_quantity_missing(100)

      Claims.NewPage.select_delivering_barge(delivering_barge.id, :quantity)
      Claims.NewPage.place_notice(:supplier)
      Claims.NewPage.enter_additional_information("Your fuel sucked!")
      Claims.NewPage.submit_claim()

      :timer.sleep(1_000)

      assert_email_delivered_with(
        subject: "A Quantity Claim has been made for Auction #{auction.id}"
      )

      :timer.sleep(500)

      claims = Deliveries.claims_for_auction(auction)
      assert Claims.EditPage.is_current_path?(auction.id, hd(claims).id)
      assert Claims.ShowPage.has_success_message?("Claim successfully made.")
      assert Claims.ShowPage.has_claims_details?(hd(claims), :quantity)
    end

    test "can place a new density claim", %{
      buyer: buyer,
      auction: auction,
      fixture: fixture,
      delivering_barge: delivering_barge
    } do
      login_user(buyer)
      Claims.NewPage.visit(auction.id)
      assert Claims.NewPage.is_current_path?(auction.id)
      Claims.NewPage.select_claim_type(:density)
      Claims.NewPage.select_fixture(fixture.id, :density)

      Claims.NewPage.enter_quantity_difference(100)

      Claims.NewPage.select_delivering_barge(delivering_barge.id, :density)
      Claims.NewPage.place_notice(:supplier)
      Claims.NewPage.enter_additional_information("Your fuel sucked!")
      Claims.NewPage.submit_claim()

      :timer.sleep(1_000)

      assert_email_delivered_with(
        subject: "A Density Claim has been made for Auction #{auction.id}"
      )

      :timer.sleep(500)

      claims = Deliveries.claims_for_auction(auction)
      assert Claims.EditPage.is_current_path?(auction.id, hd(claims).id)
      assert Claims.ShowPage.has_success_message?("Claim successfully made.")
      assert Claims.ShowPage.has_claims_details?(hd(claims), :density)
    end

    test "can place a new quality claim", %{
      buyer: buyer,
      auction: auction,
      fixture: fixture,
      delivering_barge: delivering_barge
    } do
      login_user(buyer)
      Claims.NewPage.visit(auction.id)
      assert Claims.NewPage.is_current_path?(auction.id)
      Claims.NewPage.select_claim_type(:quality)
      Claims.NewPage.select_fixture(fixture.id, :quality)

      Claims.NewPage.enter_quality_description("Your fuel really sucked...")

      Claims.NewPage.select_delivering_barge(delivering_barge.id, :quality)
      Claims.NewPage.place_notice(:supplier)
      Claims.NewPage.enter_additional_information("Your fuel sucked!")
      Claims.NewPage.submit_claim()

      claims = Deliveries.claims_for_auction(auction)
      assert Claims.EditPage.is_current_path?(auction.id, hd(claims).id)
      assert Claims.ShowPage.has_success_message?("Claim successfully made.")
      assert Claims.ShowPage.has_claims_details?(hd(claims), :quality)

      :timer.sleep(1_000)

      assert_email_delivered_with(
        subject: "A Quality Claim has been made for Auction #{auction.id}"
      )
    end
  end

  describe "supplier" do
    test "cannot place a claim", %{supplier: supplier, auction: auction} do
      login_user(supplier)
      AuctionShowPage.visit(auction.id)
      assert AuctionShowPage.is_current_path?(auction.id)
      assert AuctionShowPage.auction_status() == "CLOSED"

      refute AuctionShowPage.has_place_claim_button?()
      Claims.NewPage.visit(auction.id)
      assert Claims.NewPage.has_content?("404")
    end
  end
end
