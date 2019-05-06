defmodule Oceanconnect.DeliveriesTest do
  use Oceanconnect.DataCase

  alias Oceanconnect.Deliveries
  alias Oceanconnect.Deliveries.{QuantityClaim, ClaimResponse}

  alias Oceanconnect.Auctions

  describe "quantity claims" do
    setup do
      buyer_company = insert(:company)
      buyer = insert(:user, company: buyer_company)
      supplier_company = insert(:company, is_supplier: true)
      _supplier = insert(:user)

      auction =
        insert(:auction, buyer: buyer_company, suppliers: [supplier_company])
        |> Auctions.fully_loaded()

      delivering_barge =
        insert(:auction_barge,
          auction: auction,
          supplier: supplier_company,
          approval_status: "APPROVED"
        )

      auction_state = close_auction!(auction)
      _auction_fixtures = Auctions.create_fixtures_from_state(auction_state)

      claim_params = %{
        "type" => "quantity",
        "supplier_id" => supplier_company.id,
        "receiving_vessel_id" => hd(auction.vessels).id,
        "delivered_fuel_id" => hd(auction.auction_vessel_fuels).fuel.id,
        "notice_recipient_type" => "supplier",
        "delivering_barge_id" => delivering_barge.barge.id,
        "quantity_missing" => 100,
        "price_per_unit" => 100,
        "total_fuel_value" => 100 * 100,
        "additional_information" => "Your fuel sucked!",
        "auction_id" => auction.id
      }

      quantity_claim =
        insert(:quantity_claim,
          type: "quantity",
          quantity_missing: 100,
          price_per_unit: 100.00,
          total_fuel_value: 100.00,
          auction: auction,
          supplier: supplier_company,
          buyer: buyer_company,
          notice_recipient_type: "supplier",
          notice_recipient: supplier_company,
          receiving_vessel: hd(auction.vessels),
          delivered_fuel: hd(auction.auction_vessel_fuels).fuel,
          delivering_barge: delivering_barge.barge
        )

      update_params = %{quantity_missing: 200}

      {:ok,
       %{claim_params: claim_params, quantity_claim: quantity_claim, update_params: update_params, buyer: buyer}}
    end

    test "change_quantity_claim/1 returns a claim changeset" do
      assert %Ecto.Changeset{} = Deliveries.change_quantity_claim(%QuantityClaim{})
    end

    test "create_quantity_claim/1 with valid attrs creates a quantity claim", %{
      claim_params: claim_params
    } do
      assert {:ok, %QuantityClaim{id: claim_id} = claim} =
               Deliveries.create_quantity_claim(claim_params)

      assert %QuantityClaim{type: "quantity"} = Deliveries.get_quantity_claim(claim_id)
    end

    test "update_quantity_claim/2 with valid attrs creates a quantity claim", %{
      update_params: update_params,
      quantity_claim: claim
    } do
      assert {:ok, %QuantityClaim{id: claim_id}} =
               Deliveries.update_quantity_claim(claim, update_params)

      updated_claim = Deliveries.get_quantity_claim(claim_id)
      assert updated_claim.id == claim.id
      assert updated_claim.quantity_missing == 200
    end

    test "create_claim_response/1 with valid attrs creates a claim response", %{buyer: buyer, claim: claim} do
      assert %{:ok, %ClaimResponse{id: claim_response_id}} = Deliveries.create_claim_response(%{author_id: buyer.id, quantity_claim_id: claim.id, content: "Your fuel sucked!"})
      assert %ClaimResponse{content: "Your fuel sucked!"} = Deliveries.get_claim_response(claim_response_id)
    end
  end
end
