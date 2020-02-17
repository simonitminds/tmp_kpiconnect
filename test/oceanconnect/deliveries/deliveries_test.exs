defmodule Oceanconnect.DeliveriesTest do
  use Oceanconnect.DataCase

  alias Oceanconnect.Deliveries
  alias Oceanconnect.Deliveries.{Claim, ClaimResponse}

  alias Oceanconnect.Auctions

  setup do
    buyer_company = insert(:company)
    buyer = insert(:user, company: buyer_company)
    supplier_company = insert(:company, is_supplier: true)
    supplier = insert(:user, company: supplier_company)

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
       auction: auction,
       claim_params: claim_params,
       claim: claim,
       update_params: update_params,
       buyer: buyer,
       supplier: supplier,
       supplier_company: supplier_company
     }}
  end

  describe "claims" do
    test "change_claim/1 returns a claim changeset" do
      assert %Ecto.Changeset{} = Deliveries.change_claim(%Claim{})
    end

    test "create_claim/1 with valid attrs creates a claim", %{
      claim_params: claim_params,
      buyer: buyer
    } do
      assert {:ok, %Claim{id: claim_id} = claim} = Deliveries.create_claim(claim_params, buyer)

      assert %Claim{type: "quantity"} = Deliveries.get_claim(claim_id)
    end

    test "create_claim/1 with invalid attrs creates a claim", %{
      claim_params: claim_params
    } do
      invalid_params =
        claim_params
        |> Map.merge(%{"quantity_missing" => ""})

      assert {:error, %Ecto.Changeset{}} = Deliveries.create_claim(invalid_params)
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
  end

  describe "claim_responses" do
    test "create_claim_response/2 with valid attrs creates a claim response", %{
      buyer: buyer,
      claim: claim
    } do
      assert {:ok, %ClaimResponse{id: claim_response_id}} =
               Deliveries.create_claim_response(
                 %{
                   author_id: buyer.id,
                   claim_id: claim.id,
                   content: "Your fuel sucked!"
                 },
                 claim,
                 buyer
               )

      assert %ClaimResponse{content: "Your fuel sucked!"} =
               Deliveries.get_claim_response(claim_response_id)
    end

    test "create_claim_response/2 as a supplier with missing content doesn't create a claim response",
         %{
           supplier: supplier,
           claim: claim
         } do
      assert {:error, %Ecto.Changeset{}} =
               Deliveries.create_claim_response(
                 %{
                   author_id: supplier.id,
                   claim_id: claim.id
                 },
                 claim,
                 supplier
               )
    end

    test "get_claim_responses_for_claims/1 returns list of claim_responses for claim", %{
      claim: claim,
      supplier_company: supplier_company
    } do
      unrelated_claim =
        insert(:claim,
          supplier: supplier_company,
          notice_recipient: supplier_company
        )

      _unrelated_claim_response = insert(:claim_response, claim: unrelated_claim)
      claim_responses = insert_list(2, :claim_response, claim: claim)

      assert MapSet.equal?(
               claim_responses |> Enum.map(& &1.id) |> MapSet.new(),
               [claim]
               |> Deliveries.get_claim_responses_for_claims()
               |> Enum.map(& &1.id)
               |> MapSet.new()
             )
    end

    test "get_claim_responses_for_claims/1 returns claim_responses multiple claims", %{
      auction: auction,
      claim: claim,
      supplier_company: supplier_company
    } do
      claim_for_different_supplier = insert(:claim, auction: auction)
      diff_supplier_claim_response = insert(:claim_response, claim: claim_for_different_supplier)

      other_claim_for_supplier = insert(:claim, auction: auction, supplier: supplier_company)

      other_claim_response = insert(:claim_response, claim: other_claim_for_supplier)
      claim_responses = insert_list(2, :claim_response, claim: claim)

      assert MapSet.equal?(
               [diff_supplier_claim_response, other_claim_response]
               |> Kernel.++(claim_responses)
               |> Enum.map(& &1.id)
               |> MapSet.new(),
               [claim, claim_for_different_supplier, other_claim_for_supplier]
               |> Deliveries.get_claim_responses_for_claims()
               |> Enum.map(& &1.id)
               |> MapSet.new()
             )
    end
  end
end
