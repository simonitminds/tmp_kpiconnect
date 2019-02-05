defmodule Oceanconnect.Admin.AuctionFixture.EditTest do
  use Oceanconnect.FeatureCase
  alias Oceanconnect.{AuctionShowPage}
  alias Oceanconnect.Admin, as: Admin

  alias Oceanconnect.Auctions
  alias Oceanconnect.Auctions.{AuctionFixture}

  hound_session()

  setup do
    admin_user = insert(:user, is_admin: true)
    _user = insert(:user, is_admin: false)
    _company = insert(:company)
    %{auction: auction, vessel_fuels: [vessel_fuel1, _vessel_fuel2]} = create_closed_auction()
    auction_fixtures = Auctions.fixtures_for_auction(auction)
    {:ok, %{admin_user: admin_user, auction: auction, vessel_fuel1: vessel_fuel1, auction_fixtures: auction_fixtures }}
  end

  test "visiting the auction fixture index page shows a list fixtures for the auction", %{
    admin_user: admin_user,
    auction: %{id: auction_id},
    vessel_fuel1: vessel_fuel1,
    auction_fixtures: [auction_fixture1, auction_fixture2]
  } do
    login_user(admin_user)
    AuctionShowPage.visit(auction_id)
    AuctionShowPage.view_auction_fixtures
    assert Admin.Fixture.IndexPage.is_current_path?(auction_id)
    assert Admin.Fixture.IndexPage.has_fixture?(auction_fixture1)
    assert Admin.Fixture.IndexPage.has_fixture?(auction_fixture2)
  end

  def create_closed_auction do
    buyer_company = insert(:company, credit_margin_amount: 5.00)
    buyer = insert(:user, company: buyer_company)
    supplier_company = insert(:company, is_supplier: true)
    supplier_company2 = insert(:company, is_supplier: true)
    supplier = insert(:user, company: supplier_company)
    supplier2 = insert(:user, company: supplier_company2)
    insert(:company, name: "Ocean Connect Marine")

    fuel = insert(:fuel)
    [vessel_fuel1, vessel_fuel2] = insert_list(2, :vessel_fuel, fuel: fuel)

    auction =
      insert(
        :auction,
        buyer: buyer_company,
        suppliers: [supplier_company, supplier_company2],
        auction_vessel_fuels: [vessel_fuel1, vessel_fuel2],
        is_traded_bid_allowed: true
      )
      |> Auctions.fully_loaded()

    {:ok, _pid} =
      start_supervised(
        {Oceanconnect.Auctions.AuctionSupervisor,
         {auction, %{exclude_children: [:auction_reminder_timer]}}}
      )

    Auctions.start_auction(auction)

    _supplier1_bid1 =
      create_bid(1.25, nil, supplier.company_id, "#{vessel_fuel1.id}", auction)
      |> Auctions.place_bid()

    _supplier1_bid2 =
      create_bid(1.25, nil, supplier.company_id, "#{vessel_fuel2.id}", auction)
      |> Auctions.place_bid()

    _supplier2_bid1 =
      create_bid(1.50, nil, supplier2.company_id, "#{vessel_fuel1.id}", auction)
      |> Auctions.place_bid()

    _supplier2_bid2 =
      create_bid(1.50, nil, supplier2.company_id, "#{vessel_fuel2.id}", auction)
      |> Auctions.place_bid()

    Auctions.end_auction(auction)

    login_user(buyer)
    AuctionShowPage.visit(auction.id)
    AuctionShowPage.select_solution(:best_overall)
    :timer.sleep(100)
    AuctionShowPage.accept_bid()
    :timer.sleep(500)

    %{auction: auction, vessel_fuels: [vessel_fuel1, vessel_fuel2]}
  end
end
