defmodule OceanconnectWeb.ClaimsControllerTest do
  use OceanconnectWeb.ConnCase

  alias Oceanconnect.Deliveries
  alias Oceanconnect.Deliveries.QuantityClaim

  alias Oceanconnect.Auctions

  setup do
    ocm = insert(:company, is_ocm: true)
    _ocm_admin = insert(:user, company: ocm, is_admin: true)
    buyer_company = insert(:company)
    buyer = insert(:user, company: buyer_company)
    supplier_company = insert(:company, is_supplier: true)
    supplier = insert(:user)

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
      "additional_information" => "Your fuel sucked!"
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

    {:ok,
     %{
       auction: auction,
       buyer: buyer,
       supplier: supplier,
       claim_params: claim_params,
       quantity_claim: quantity_claim
     }}
  end

  describe "buyer" do
    setup %{buyer: buyer} do
      conn =
        build_conn()
        |> login_user(buyer)

      {:ok, %{conn: conn}}
    end

    test "can visit new claim action", %{conn: conn, auction: auction} do
      conn = get(conn, claim_path(conn, :new, auction.id))

      changeset = Deliveries.change_quantity_claim(%QuantityClaim{})
      fixtures = Auctions.fixtures_for_auction(auction)

      assert %{
               assigns: %{
                 changeset: ^changeset,
                 auction: assigns_auction,
                 fixtures: assigns_fixtures,
                 claim: nil
               }
             } = conn

      assert assigns_auction.id == auction.id
      assert Enum.map(assigns_fixtures, & &1.id) == Enum.map(fixtures, & &1.id)
      assert html_response(conn, 200) =~ "Make Claim"
    end

    test "can create a new claim", %{conn: conn, auction: auction, claim_params: claim_params} do
      conn =
        post(conn, claim_path(conn, :create, auction.id, %{"quantity_claim" => claim_params}))

      claims = Deliveries.claims_for_auction(auction)
      [claim] = tl(claims)
      assert html_response(conn, 302) =~ "/auctions/#{auction.id}/claims/#{claim.id}"
    end

    test "can visit edit claim action", %{conn: conn, auction: auction, quantity_claim: claim} do
      conn = get(conn, claim_path(conn, :edit, auction.id, claim.id))

      assert %{
               assigns: %{
                 auction: assigns_auction,
                 claim: assigns_claim
               }
             } = conn

      assert assigns_auction.id == auction.id
      assert assigns_claim.id == claim.id
      assert html_response(conn, 200) =~ "Update Claim"
    end

    test "can update a claim", %{conn: conn, auction: auction, quantity_claim: claim} do
      update_params = %{
        "response" => "hello"
      }

      conn =
        put(
          conn,
          claim_path(conn, :update, auction.id, claim.id, %{"quantity_claim" => update_params})
        )

      assert html_response(conn, 302) =~ "/auctions/#{auction.id}"
    end
  end

  describe "supplier" do
    setup %{supplier: supplier} do
      conn =
        build_conn()
        |> login_user(supplier)

      {:ok, %{conn: conn}}
    end

    test "cannot visit new claim action", %{conn: conn, auction: auction} do
      conn = get(conn, claim_path(conn, :new, auction.id))
      assert html_response(conn, 404) =~ "/auctions"
    end

    test "cannot visit edit claim action", %{conn: conn, auction: auction, quantity_claim: claim} do
      conn = get(conn, claim_path(conn, :edit, auction.id, claim.id))
      assert html_response(conn, 404) =~ "/auctions"
    end
  end
end
