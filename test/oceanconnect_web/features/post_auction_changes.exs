defmodule Oceanconnect.PostAuctionFixtureChanges do
  use Oceanconnect.FeatureCase
  alias Oceanconnect.AuctionLogPage
  alias Oceanconnect.Auctions

  hound_session()

  setup do
    buyer_company = insert(:company)
    buyer = insert(:user, company: buyer_company)
    supplier_company = insert(:company, is_supplier: true)
    supplier_company2 = insert(:company, is_supplier: true)
    supplier = insert(:user, company: supplier_company)
    insert(:company, name: "Ocean Connect Marine")

    vessel_fuel = insert(:vessel_fuel)
    vessel_fuel_id = "#{vessel_fuel.id}"

    auction =
      insert(
        :auction,
        buyer: buyer_company,
        suppliers: [supplier_company, supplier_company2],
        auction_vessel_fuels: [vessel_fuel],
        duration: 600_000
      )
      |> Auctions.fully_loaded()

    # TODO END THE AUCTION WITH A WINNING SUPPLIER SET THE PRICE AND THE QUANTITY

    {:ok, %{}}
  end
end
