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
    _auction_fixtures = Auctions.create_fixtures_from_state(auction_state)
    winning_solution = auction_state.winning_solution

    {:ok, _pid} = Oceanconnect.Notifications.NotificationsSupervisor.start_link()

    {:ok,
     %{
       buyer: buyer,
       supplier: supplier,
       supplier_company: supplier_company,
       auction: auction,
       vessel_fuels: vessel_fuels,
       delivering_barge: delivering_barge.barge
     }}
  end

  describe "buyer" do
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
      supplier_company: supplier_company,
      auction: auction,
      vessel_fuels: vessel_fuels,
      delivering_barge: delivering_barge
    } do
      login_user(buyer)
      Claims.NewPage.visit(auction.id)
      assert Claims.NewPage.is_current_path?(auction.id)
      Claims.NewPage.select_claim_type(:quantity)
      Claims.NewPage.select_supplier(supplier_company.id)

      vessel = hd(vessel_fuels).vessel
      fuel = hd(vessel_fuels).fuel
      Claims.NewPage.select_receiving_vessel(vessel.id)
      Claims.NewPage.select_delivered_fuel(fuel.id)

      quantity_missing = 100
      price_per_unit = 100
      Claims.NewPage.enter_quantity_missing(quantity_missing)
      Claims.NewPage.enter_price_per_unit(price_per_unit)
      Claims.NewPage.enter_total_fuel_value(quantity_missing * price_per_unit)

      Claims.NewPage.select_delivering_barge(delivering_barge.id)
      Claims.NewPage.place_notice(:supplier)
      Claims.NewPage.enter_additional_information("Your fuel sucked!")
      Claims.NewPage.submit_claim()

      :timer.sleep(1_000)

      assert_email_delivered_with(
        subject: "A Quantity Claim has been made for Auction #{auction.id}"
      )

      :timer.sleep(500)

      claims = Deliveries.claims_for_auction(auction)
      assert Claims.ShowPage.is_current_path?(auction.id, hd(claims).id)
      assert Claims.ShowPage.has_success_message?("Claim successfully made.")
    end

    # test "can place a new density claim", %{
    #   buyer: buyer,
    #   auction: auction,
    #   vessel_fuels: vessel_fuels,
    #   delivering_barge: delivering_barge
    # } do
    #   login_user(buyer)
    #   Claims.NewPage.visit(auction.id)
    #   assert Claims.NewPage.is_current_path?(auction.id)

    #   Claims.NewPage.select_claim_type(:density)

    #   vessel = hd(vessel_fuels).vessel
    #   fuel = hd(vessel_fuels).fuel
    #   Claims.NewPage.select_receiving_vessel(vessel.id)
    #   Claims.NewPage.select_delivered_fuel(fuel.id)

    #   quantity_difference = 100
    #   price_per_unit = 100
    #   Claims.NewPage.enter_quantity_difference(quantity_difference)
    #   Claims.NewPage.enter_price_per_unit(price_per_unit)
    #   Claims.NewPage.enter_total_fuel_value(quantity_difference * price_per_unit)

    #   Claims.NewPage.select_delivering_barge(delivering_barge.id)
    #   Claims.NewPage.place_notice(:supplier)
    #   Claims.NewPage.enter_response("Your fuel sucked!")
    #   Claims.NewPage.submit_claim()

    #   assert_email_delivered_with(subject: "A claim was made?")

    #   :timer.sleep(500)

    #   claims = Auctions.get_claims_by_auction_id(auction.id)
    #   assert Claims.ShowPage.is_current_path?(auction.id, hd(claims).id)
    #   assert Claims.ShowPage.has_success_message?() # has_content?("Claim successfully placed!")
    # end

    # test "can place a new quality claim", %{
    #   buyer: buyer,
    #   auction: auction,
    #   vessel_fuels: vessel_fuels,
    #   delivering_barge: delivering_barge
    # } do
    #   login_user(buyer)
    #   Claims.NewPage.visit(auction.id)
    #   assert Claims.NewPage.is_current_path?(auction.id)

    #   Claims.NewPage.select_claim_type(:quality)

    #   vessel = hd(vessel_fuels).vessel
    #   fuel = hd(vessel_fuels).fuel
    #   Claims.NewPage.select_receiving_vessel(vessel.id)
    #   Claims.NewPage.select_delivered_fuel(fuel.id)

    #   Claims.NewPage.enter_quality_description("Your fuel sucked!")

    #   Claims.NewPage.select_delivering_barge(delivering_barge.id)
    #   Claims.NewPage.place_notice(:supplier)
    #   Claims.NewPage.enter_response("Your fuel sucked a lot!")
    #   Claims.NewPage.submit_claim()

    #   assert_email_delivered_with(subject: "A claim was made?")

    #   :timer.sleep(500)

    #   claims = Auctions.get_claims_by_auction_id(auction.id)
    #   assert Claims.ShowPage.is_current_path?(auction.id, hd(claims).id)
    #   assert Claims.ShowPage.has_success_message?() # has_content?("Claim successfully placed!")
    # end
  end

  # describe "supplier" do
  #   test "cannot place a claim", %{supplier: supplier, auction: auction} do
  #     login_user(supplier)
  #     AuctionShowPage.visit(auction.id)
  #     assert AuctionShowPage.is_current_path?(auction.id)
  #     assert AuctionShowPage.auction_status() == "CLOSED"

  #     refute AuctionShowPage.has_place_claim_button?()
  #     Claims.NewPage.visit(auction.id)
  #     refute Claims.NewPage.is_current_path?(auction.id)
  #     assert AuctionShowPage.is_current_path?(auction.id)
  #   end
  # end
end
