defmodule Oceanconnect.AuctionRsvpFeatureTest do
  use Oceanconnect.FeatureCase
  alias Oceanconnect.Auctions
  alias Oceanconnect.Auctions.Auction
  alias Oceanconnect.Accounts.Company
  alias Oceanconnect.{AuctionRsvpPage, AuctionShowPage, AuctionIndexPage}

  setup do
    buyer_company = insert(:company)
    buyer = insert(:user, company: buyer_company)
    supplier_company = insert(:company, is_supplier: true)
    supplier_company2 = insert(:company, is_supplier: true)
    supplier = insert(:user, company: supplier_company)
    fuel = insert(:fuel)

    auction =
      insert(
        :auction,
        buyer: buyer_company,
        suppliers: [supplier_company, supplier_company2],
        auction_vessel_fuels: [build(:vessel_fuel, fuel: fuel)],
        duration: 600_000
      )
      |> Auctions.fully_loaded()

    {:ok, _pid} =
      start_supervised(
        {Oceanconnect.Auctions.AuctionSupervisor,
         {auction, %{exclude_children: [:auction_scheduler]}}}
      )

    {:ok,
     %{auction: auction, supplier: supplier, buyer: buyer, supplier_company: supplier_company}}
  end

  test "responding YES to auction invitation", %{
    auction: auction = %Auction{id: auction_id},
    supplier: supplier
  } do
    login_user(supplier)

    AuctionRsvpPage.respond_yes(auction)

    assert AuctionShowPage.is_current_path?(auction_id)
    assert AuctionRsvpPage.current_response_as_supplier(auction) == "Accept"
  end

  test "responding NO to auction invitation", %{
    auction: auction = %Auction{id: auction_id},
    supplier: supplier
  } do
    login_user(supplier)

    AuctionRsvpPage.respond_no(auction)

    assert AuctionShowPage.is_current_path?(auction_id)
    assert AuctionRsvpPage.current_response_as_supplier(auction) == "Decline"
  end

  test "responding MAYBE to auction invitation", %{
    auction: auction = %Auction{id: auction_id},
    supplier: supplier
  } do
    login_user(supplier)

    AuctionRsvpPage.respond_maybe(auction)

    assert AuctionShowPage.is_current_path?(auction_id)
    assert AuctionRsvpPage.current_response_as_supplier(auction) == "Maybe"
  end

  test "supplier can respond from the index page", %{
    auction: auction = %Auction{id: auction_id},
    supplier: supplier
  } do
    login_user(supplier)
    AuctionIndexPage.visit()
    assert AuctionIndexPage.is_current_path?()
    AuctionRsvpPage.respond_to_invitation(auction, "yes")
    assert AuctionShowPage.is_current_path?(auction_id)
    assert AuctionRsvpPage.current_response_as_supplier(auction) == "Accept"
  end

  test "buyer can view a suppliers rsvp responses", %{
    auction: auction = %Auction{id: auction_id},
    supplier: supplier,
    buyer: buyer,
    supplier_company: %Company{id: supplier_company_id}
  } do
    login_user(supplier)
    AuctionRsvpPage.respond_yes(auction)
    logout_user()

    login_user(buyer)
    AuctionShowPage.visit(auction_id)
    assert AuctionRsvpPage.supplier_response_as_buyer(supplier_company_id) == "Accept"
  end

  test "changing a response updates the response", %{
    auction: auction = %Auction{id: auction_id},
    supplier: supplier,
    buyer: buyer,
    supplier_company: %Company{id: supplier_company_id}
  } do
    login_user(supplier)
    AuctionRsvpPage.respond_yes(auction)
    logout_user()

    :timer.sleep(200)
    login_user(buyer)
    AuctionShowPage.visit(auction_id)

    assert AuctionRsvpPage.supplier_response_as_buyer(supplier_company_id) == "Accept"
    logout_user()

    login_user(supplier)
    AuctionRsvpPage.respond_no(auction)
    logout_user()

    :timer.sleep(200)
    login_user(buyer)
    AuctionShowPage.visit(auction_id)

    assert AuctionRsvpPage.supplier_response_as_buyer(supplier_company_id) == "Decline"
  end

  test "placing a bid changes a suppliers response to yes",
       %{
         auction: auction = %Auction{id: auction_id},
         supplier: supplier,
         buyer: buyer,
         supplier_company: %Company{id: supplier_company_id}
       } do
    login_user(supplier)
    AuctionRsvpPage.respond_no(auction)
    logout_user()

    :timer.sleep(200)
    login_user(buyer)
    AuctionShowPage.visit(auction_id)

    assert AuctionRsvpPage.supplier_response_as_buyer(supplier_company_id) == "Decline"

    logout_user()
    :timer.sleep(200)

    login_user(supplier)

    AuctionShowPage.visit(auction.id)
    AuctionShowPage.enter_bid(%{amount: 1.25})
    AuctionShowPage.submit_bid()
    :timer.sleep(200)
    logout_user()

    login_user(buyer)
    AuctionShowPage.visit(auction_id)

    assert AuctionRsvpPage.supplier_response_as_buyer(supplier_company_id) == "Accept"
  end
end
