defmodule Oceanconnect.AuctionRsvpFeatureTest do
  use Oceanconnect.FeatureCase
  alias Oceanconnect.Auctions
  alias Oceanconnect.Auctions.Auction
  alias Oceanconnect.{AuctionRsvpPage, AuctionShowPage}

  setup do
    buyer_company = insert(:company)
    buyer = insert(:user, company: buyer_company)
    supplier_company = insert(:company, is_supplier: true)
    supplier_company2 = insert(:company, is_supplier: true)
    supplier = insert(:user, company: supplier_company)
    fuel = insert(:fuel)
    fuel_id = "#{fuel.id}"

    auction =
      insert(
        :auction,
        buyer: buyer_company,
        suppliers: [supplier_company, supplier_company2],
        auction_vessel_fuels: [build(:vessel_fuel, fuel: fuel)],
        duration: 600_000
      ) |> Auctions.fully_loaded()


    {:ok, _pid} =
      start_supervised(
        {Oceanconnect.Auctions.AuctionSupervisor,
         {auction, %{exclude_children: [:auction_scheduler]}}}
      )

      {:ok, auction: auction, supplier: supplier}
    end

  test "responding YES to auction invitation", %{auction: auction = %Auction{id: auction_id}, supplier: supplier} do
    login_user(supplier)

    AuctionRsvpPage.respond_yes(auction)

    assert AuctionShowPage.is_current_path?(auction_id)
    assert AuctionRsvpPage.current_response_as_supplier(auction) == "Yes"
  end

  test "responding NO to auction invitation", %{auction: auction = %Auction{id: auction_id}, supplier: supplier} do
    login_user(supplier)

    AuctionRsvpPage.respond_no(auction)

    assert AuctionShowPage.is_current_path?(auction_id)
    assert AuctionRsvpPage.current_response_as_supplier(auction) == "No"
  end

  test "responding MAYBE to auction invitation", %{auction: auction = %Auction{id: auction_id}, supplier: supplier} do
    login_user(supplier)

    AuctionRsvpPage.respond_maybe(auction)

    assert AuctionShowPage.is_current_path?(auction_id)
    assert AuctionRsvpPage.current_response_as_supplier(auction) == "Maybe"
  end

  test "buyer can view a suppliers rsvp responses"

  test "changing a response updates the response"
end
