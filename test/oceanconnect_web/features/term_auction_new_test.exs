defmodule Oceanconnect.TermAuctionNewTest do
  use Oceanconnect.FeatureCase
  alias Oceanconnect.{AuctionNewPage, AuctionShowPage}

  hound_session()

  setup do
    buyer_company = insert(:company, credit_margin_amount: 5.40)
    buyer = insert(:user, company: buyer_company)

    login_user(buyer)

    fuels = insert_list(2, :fuel)
    buyer_vessels = insert_list(3, :vessel, company: buyer_company)
    supplier_companies = insert_list(3, :company, is_supplier: true)

    selected_company1 = Enum.at(supplier_companies, 0)
    selected_company2 = Enum.at(supplier_companies, 1)

    suppliers = [selected_company1, selected_company2]

    port = insert(:port, companies: [buyer_company] ++ supplier_companies)

    valid_start_time =
      DateTime.utc_now()
      |> DateTime.to_unix()
      |> Kernel.+(100_000)
      |> DateTime.from_unix!()

    auction_params = %{
      anonymous_bidding: false,
      is_traded_bid_allowed: true,
      terminal: "AA",
      term_start_date: valid_start_time,
      term_end_date: valid_start_time,
      scheduled_start_time: valid_start_time,
      suppliers: [
        %{
          id: selected_company1.id
        },
        %{
          id: selected_company2.id
        }
      ],
      duration: 10
    }

    show_params = %{
      vessels: buyer_vessels,
      port: port.name,
      suppliers: suppliers
    }

    {:ok,
     %{
       buyer: buyer,
       buyer_vessels: buyer_vessels,
       params: auction_params,
       show_params: show_params,
       buyer_company: buyer_company,
       suppliers: supplier_companies,
       port: port,
       fuels: fuels
     }}
  end

  describe "creating a forward-fixed term auction" do
    test "visiting the new auction page" do
      AuctionNewPage.visit()
      AuctionNewPage.select_auction_type(:forward_fixed)

      assert AuctionNewPage.has_fields?([
               "type",
               "terminal",
               "additional_information",
               "anonymous_bidding",
               "scheduled_start",
               "term_start_date",
               "term_end_date",
               "term_fuel_quantity",
               "term_fuel_id",
               "is_traded_bid_allowed",
               "po",
               "port_id",
               "select-port",
               "select-vessel"
             ])
    end

    test "creating a forward-fixed auction", %{
      params: params,
      show_params: show_params,
      port: port,
      fuels: [selected_fuel | _rest],
      buyer_company: buyer_company,
      buyer_vessels: [selected_vessel | _reset]
    } do
      AuctionNewPage.visit()
      AuctionNewPage.select_auction_type(:forward_fixed)

      AuctionNewPage.select_port(port.id)
      AuctionNewPage.fill_form(params)
      AuctionNewPage.add_vessels([selected_vessel])
      AuctionNewPage.add_term_fuel(selected_fuel.id)
      AuctionNewPage.add_term_fuel_quantity(1500)

      assert AuctionNewPage.credit_margin_amount() ==
               :erlang.float_to_binary(buyer_company.credit_margin_amount, decimals: 2)

      AuctionNewPage.submit()
      assert current_path() =~ ~r/auctions\/\d/

      assert AuctionShowPage.has_values_from_params?(
               Map.put(show_params, :vessels, [selected_vessel])
             )
    end
  end
end
