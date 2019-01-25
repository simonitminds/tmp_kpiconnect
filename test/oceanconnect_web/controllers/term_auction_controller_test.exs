defmodule OceanconnectWeb.TermAuctionControllerTest do
  use OceanconnectWeb.ConnCase

  alias Oceanconnect.Auctions

  setup do
    buyer_company = insert(:company, is_supplier: true)
    buyer = insert(:user, company: buyer_company)
    buyer_vessels = insert_list(3, :vessel, company: buyer_company)
    selected_vessel = hd(buyer_vessels)
    fuels = insert_list(3, :fuel)
    selected_fuel = hd(fuels)
    supplier_company = insert(:company, is_supplier: true)
    supplier = insert(:user, company: supplier_company)
    port = insert(:port, companies: [buyer_company, supplier_company])

    term_auction_params =
      string_params_for(
        :term_auction,
        port: port
      )
      |> Oceanconnect.Utilities.maybe_convert_date_times()

    authed_conn = login_user(build_conn(), buyer)

    {:ok,
     %{
       conn: authed_conn,
       term_auction_params: term_auction_params,
       buyer: buyer_company,
       supplier: supplier,
       supplier_company: supplier_company,
       selected_vessel: selected_vessel,
       selected_fuel: selected_fuel
     }}
  end

  describe "new forward fixed auction" do
    test "redirects to show when data is valid", %{
      conn: conn,
      term_auction_params: term_auction_params,
      buyer: buyer,
      supplier_company: supplier_company,
      selected_vessel: selected_vessel,
      selected_fuel: selected_fuel
    } do
      updated_params =
        term_auction_params
        |> Map.put("duration", round(term_auction_params["duration"] / 60_000))

      conn = post(conn, auction_path(conn, :create), auction: updated_params)
      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == auction_path(conn, :show, id)

      auction = Auctions.get_auction!(id)
      conn = get(conn, auction_path(conn, :show, id))
      assert html_response(conn, 200) =~ "window.userToken"
      assert auction.buyer_id == buyer.id
      assert hd(auction.suppliers).id == supplier_company.id
    end
  end
end
