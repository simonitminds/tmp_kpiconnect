defmodule Oceanconnect.Admin.AuctionFixture.EditTest do
  use Oceanconnect.FeatureCase
  alias Oceanconnect.Admin.AuctionFixture.{IndexPage, EditPage}
  alias Oceanconnect.{AuctionShowPage, AuctionNewPage}
  alias Oceanconnect.Admin, as: Admin

  alias Oceanconnect.Auctions

  hound_session()

  setup do
    admin_user = insert(:user, is_admin: true)
    user = insert(:user, is_admin: false)
    company = insert(:company)
    %{auction: auction, vessel_fuels: [vessel_fuel1, vessel_fuel2]} = create_closed_auction

    {:ok, %{admin_user: admin_user, auction: auction, vessel_fuel1: vessel_fuel1}}
  end

  test "visiting the auction fixture index page shows a list fixtures for the auction", %{
    admin_user: admin_user,
    auction: %{id: auction_id},
    vessel_fuel1: vessel_fuel1
  } do
    login_user(admin_user)
    Admin.Fixture.IndexPage.visit(auction_id)
    assert Admin.Fixture.IndexPage.is_current_path?(auction_id)
    assert Admin.Fixture.IndexPage.has_fixture?(vessel_fuel1.id)
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

    supplier1_bid1 =
      create_bid(1.25, nil, supplier.company_id, "#{vessel_fuel1.id}", auction)
      |> Auctions.place_bid()

    supplier1_bid2 =
      create_bid(1.25, nil, supplier.company_id, "#{vessel_fuel2.id}", auction)
      |> Auctions.place_bid()

    supplier2_bid1 =
      create_bid(1.50, nil, supplier2.company_id, "#{vessel_fuel1.id}", auction)
      |> Auctions.place_bid()

    supplier2_bid2 =
      create_bid(1.50, nil, supplier2.company_id, "#{vessel_fuel2.id}", auction)
      |> Auctions.place_bid()

    Auctions.end_auction(auction)

    login_user(buyer)
    AuctionShowPage.visit(auction.id)
    AuctionShowPage.select_solution(:best_overall)
    :timer.sleep(100)
    AuctionShowPage.accept_bid()

    %{auction: auction, vessel_fuels: [vessel_fuel1, vessel_fuel2]}
  end
end
