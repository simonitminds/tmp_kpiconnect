defmodule OceanconnectWeb.AuctionRsvpControllerTest do
  use OceanconnectWeb.ConnCase

  alias Oceanconnect.Auctions
  alias Oceanconnect.Auctions.{Auction}

  setup do
    buyer_company = insert(:company)
    supplier_company = insert(:company, is_supplier: true)
    supplier_company2 = insert(:company, is_supplier: true)
    supplier = insert(:user, company: supplier_company)

    auction =
      insert(
        :auction,
        buyer: buyer_company,
        suppliers: [supplier_company, supplier_company2],
        duration: 600_000
      )
      |> Auctions.fully_loaded()

    other_auction = insert(:auction)

    {:ok, _pid} =
      start_supervised(
        {Oceanconnect.Auctions.AuctionSupervisor,
         {auction, %{exclude_children: [:auction_scheduler]}}}
      )

    supplier_company_id = supplier_company.id

    conn =
      build_conn()
      |> login_user(supplier)


    {:ok, %{conn: conn, auction: auction, supplier: supplier, supplier_company_id: supplier_company_id, other_auction: other_auction}}
  end

  test "responding via query param sets response", %{
    conn: conn,
    auction: %Auction{id: auction_id},
    supplier_company_id: supplier_company_id
  } do

    updated_conn = put(conn, auction_rsvp_path(conn, :update, auction_id, %{"response" => "yes"}))
    assert redirected_to(updated_conn) == auction_path(conn, :show, auction_id)
    assert Auctions.get_auction_supplier(auction_id, supplier_company_id).participation == "yes"

    updated_conn = put(conn, auction_rsvp_path(conn, :update, auction_id, %{"response" => "no"}))
    assert redirected_to(updated_conn) == auction_path(conn, :show, auction_id)
    assert Auctions.get_auction_supplier(auction_id, supplier_company_id).participation == "no"

    updated_conn = put(conn, auction_rsvp_path(conn, :update, auction_id, %{"response" => "maybe"}))
    assert redirected_to(updated_conn) == auction_path(conn, :show, auction_id)
    assert Auctions.get_auction_supplier(auction_id, supplier_company_id).participation == "maybe"
  end

  test "responding to an auction you're not invited to does nothing", %{
    conn: conn,
    supplier_company_id: supplier_company_id,
    other_auction: %Auction{id: other_auction_id}
  } do
    updated_conn = put(conn, auction_rsvp_path(conn, :update, other_auction_id, %{"response" => "yes"}))
    assert html_response(updated_conn, 302)
    assert redirected_to(updated_conn) == auction_path(conn, :index)
    refute Auctions.get_auction_supplier(other_auction_id, supplier_company_id)
  end
end
