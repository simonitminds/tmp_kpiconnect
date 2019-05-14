defmodule Oceanconnect.DeliveriesTest do
  use Oceanconnect.DataCase

  alias Oceanconnect.Deliveries
  alias Oceanconnect.Deliveries.{Claim, ClaimResponse}

  alias Oceanconnect.Auctions

  describe "claims" do
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
      {:ok, auction_fixtures} = Auctions.create_fixtures_from_state(auction_state)

      claim_params = %{
        "type" => "quantity",
        "fixture_id" => hd(auction_fixtures).id,
        "supplier_id" => supplier_company.id,
        "receiving_vessel_id" => hd(auction.vessels).id,
        "delivered_fuel_id" => hd(auction.auction_vessel_fuels).fuel.id,
        "notice_recipient_type" => "supplier",
        "delivering_barge_id" => delivering_barge.barge.id,
        "quantity_missing" => 100,
        "price_per_unit" => 100,
        "total_fuel_value" => 100 * 100,
        "additional_information" => "Your fuel sucked!",
        "auction_id" => auction.id,
        "buyer_id" => buyer_company.id
      }

      claim =
        insert(:claim,
          type: "quantity",
          quantity_missing: 100.0,
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
       %{
         claim_params: claim_params,
         claim: claim,
         update_params: update_params,
         buyer: buyer
       }}
    end

    test "change_claim/1 returns a claim changeset" do
      assert %Ecto.Changeset{} = Deliveries.change_claim(%Claim{})
    end

    test "create_claim/1 with valid attrs creates a claim", %{
      claim_params: claim_params
    } do
      assert {:ok, %Claim{id: claim_id} = claim} = Deliveries.create_claim(claim_params)

      assert %Claim{type: "quantity"} = Deliveries.get_claim(claim_id)
    end

    test "update_claim/2 with valid attrs creates a claim", %{
      update_params: update_params,
      claim: claim
    } do
      assert {:ok, %Claim{id: claim_id}} = Deliveries.update_claim(claim, update_params)

      updated_claim = Deliveries.get_claim(claim_id)
      assert updated_claim.id == claim.id
      assert updated_claim.quantity_missing |> Decimal.to_integer() == 200
    end

    test "create_claim_response/1 with valid attrs creates a claim response", %{
      buyer: buyer,
      claim: claim
    } do
      assert {:ok, %ClaimResponse{id: claim_response_id}} =
               Deliveries.create_claim_response(%{
                 author_id: buyer.id,
                 claim_id: claim.id,
                 content: "Your fuel sucked!"
               })

      assert %ClaimResponse{content: "Your fuel sucked!"} =
               Deliveries.get_claim_response(claim_response_id)
    end
  end
end
