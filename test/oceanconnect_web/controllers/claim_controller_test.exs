defmodule OceanconnectWeb.ClaimsControllerTest do
  use OceanconnectWeb.ConnCase

  alias Oceanconnect.Deliveries
  alias Oceanconnect.Deliveries.Claim

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
    {:ok, auction_fixtures} = Auctions.create_fixtures_from_state(auction_state)

    claim_params = %{
      "type" => "quantity",
      "quantity_fixture_id" => hd(auction_fixtures).id,
      "notice_recipient_type" => "supplier",
      "quantity_delivering_barge_id" => delivering_barge.barge.id,
      "quantity_quantity_missing" => 100,
      "additional_information" => "Your fuel sucked!"
    }

    density_claim_params = %{
      "type" => "density",
      "density_fixture_id" => hd(auction_fixtures).id,
      "notice_recipient_type" => "supplier",
      "density_delivering_barge_id" => delivering_barge.barge.id,
      "density_quantity_difference" => 100,
      "additional_information" => "Your fuel sucked!"
    }

    quality_claim_params = %{
      "type" => "quality",
      "quality_fixture_id" => hd(auction_fixtures).id,
      "notice_recipient_type" => "supplier",
      "quality_delivering_barge_id" => delivering_barge.barge.id,
      "quality_quality_description" => "This fuel sucked a whole lot.",
      "additional_information" => "Your fuel sucked!"
    }

    claim =
      insert(:claim,
        type: "quantity",
        quantity_missing: 100,
        fixture: hd(auction_fixtures),
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
       density_claim_params: density_claim_params,
       quality_claim_params: quality_claim_params,
       claim: claim
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

      changeset = Deliveries.change_claim(%Claim{})
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

    test "can create a new quantity claim", %{
      conn: conn,
      auction: auction,
      claim_params: claim_params
    } do
      conn = post(conn, claim_path(conn, :create, auction.id, %{"claim" => claim_params}))

      claims = Deliveries.claims_for_auction(auction)
      [claim] = tl(claims)
      assert html_response(conn, 302) =~ "/auctions/#{auction.id}/claims/#{claim.id}"
    end

    test "can create a new density claim", %{
      conn: conn,
      auction: auction,
      density_claim_params: claim_params
    } do
      conn = post(conn, claim_path(conn, :create, auction.id, %{"claim" => claim_params}))

      claims = Deliveries.claims_for_auction(auction)
      [claim] = tl(claims)
      assert html_response(conn, 302) =~ "/auctions/#{auction.id}/claims/#{claim.id}"
    end

    test "can create a new quality claim", %{
      conn: conn,
      auction: auction,
      quality_claim_params: claim_params
    } do
      conn = post(conn, claim_path(conn, :create, auction.id, %{"claim" => claim_params}))

      claims = Deliveries.claims_for_auction(auction)
      [claim] = tl(claims)
      assert html_response(conn, 302) =~ "/auctions/#{auction.id}/claims/#{claim.id}"
    end

    test "can visit edit claim action", %{conn: conn, auction: auction, claim: claim} do
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

    test "can update a claim", %{conn: conn, auction: auction, claim: claim} do
      update_params = %{
        "response" => "hello"
      }

      conn =
        put(
          conn,
          claim_path(conn, :update, auction.id, claim.id, %{"claim" => update_params})
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

    test "cannot visit edit claim action", %{conn: conn, auction: auction, claim: claim} do
      conn = get(conn, claim_path(conn, :edit, auction.id, claim.id))
      assert html_response(conn, 404) =~ "/auctions"
    end
  end
end
