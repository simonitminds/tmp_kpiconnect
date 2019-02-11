defmodule Oceanconnect.TermAuctionNewTest do
  use Oceanconnect.FeatureCase
  alias Oceanconnect.{AuctionNewPage, AuctionShowPage}

  hound_session()

  setup do
    buyer_company = insert(:company, credit_margin_amount: 5.40)
    buyer = insert(:user, company: buyer_company)
    buyer_company_with_no_credit = insert(:company, credit_margin_amount: nil)
    buyer_with_no_credit = insert(:user, company: buyer_company_with_no_credit)
    login_user(buyer)
    fuels = insert_list(2, :fuel)
    selected_fuel = hd(fuels)
    buyer_vessels = insert_list(3, :vessel, company: buyer_company)
    supplier_companies = insert_list(3, :company, is_supplier: true)

    port =
      insert(:port, companies: [buyer_company, buyer_company_with_no_credit] ++ supplier_companies)

    selected_vessel = hd(buyer_vessels)
    selected_company1 = Enum.at(supplier_companies, 0)
    selected_company2 = Enum.at(supplier_companies, 2)

    valid_start_time =
      DateTime.utc_now()
      |> DateTime.to_unix()
      |> Kernel.+(100_000)
      |> DateTime.from_unix!()

    date_time = DateTime.utc_now()
    suppliers = [selected_company1, selected_company2]

    auction_params = %{
      anonymous_bidding: false,
      duration: 10,
      terminal: "AA",
      is_traded_bid_allowed: true,
      scheduled_start_date: valid_start_time,
      scheduled_start_time: valid_start_time,
      start_date_date: date_time,
      end_date_date: date_time,
      fuel_quantity: 15000,
      suppliers: [
        %{
          id: selected_company1.id
        },
        %{
          id: selected_company2.id
        }
      ]
    }

    show_params = %{
      port: port.name,
      suppliers: suppliers,
      terminal: "AA",
      fuel: selected_fuel.name,
      fuel_quantity: "15000"
    }

    {:ok,
     %{
       buyer: buyer,
       buyer_with_no_credit: buyer_with_no_credit,
       buyer_vessels: buyer_vessels,
       params: auction_params,
       buyer_company: buyer_company,
       show_params: show_params,
       suppliers: suppliers,
       port: port,
       fuels: fuels,
       selected_fuel: selected_fuel,
       selected_vessel: selected_vessel,
       date_time: date_time
     }}
  end

  test "visting the new auction page for a term auction" do
    AuctionNewPage.visit()
    AuctionNewPage.select_auction_type(:forward_fixed)

    assert AuctionNewPage.has_fields?([
             "additional_information",
             "anonymous_bidding",
             "duration",
             "start_date",
             "end_date",
             "fuel_quantity",
             "is_traded_bid_allowed",
             "po",
             "port_id",
             "scheduled_start",
             "select-fuel",
             "select-port",
             "select-vessel",
             "terminal"
           ])
  end

  test "vessels list is filtered by buyer company", %{buyer_vessels: buyer_vessels} do
    AuctionNewPage.visit()
    AuctionNewPage.select_auction_type(:forward_fixed)
    assert AuctionNewPage.buyer_vessels_in_vessel_list?(buyer_vessels)
  end

  test "port selection reveals port agent and supplier list", %{port: port} do
    AuctionNewPage.visit()
    AuctionNewPage.select_auction_type(:forward_fixed)
    AuctionNewPage.select_port(port.id)

    assert AuctionNewPage.has_fields?([
             "port_agent",
             "suppliers"
           ])
  end

  test "supplier list is filtered by port", %{suppliers: suppliers, port: port} do
    AuctionNewPage.visit()
    AuctionNewPage.select_auction_type(:forward_fixed)
    AuctionNewPage.select_port(port.id)

    assert AuctionNewPage.has_suppliers?(suppliers)
    assert AuctionNewPage.supplier_count(suppliers) == 2
  end

  test "creating a term auction", %{
    params: params,
    show_params: show_params,
    port: port,
    selected_fuel: selected_fuel,
    buyer_company: buyer_company,
    buyer_vessels: [selected_vessel | _reset]
  } do
    AuctionNewPage.visit()
    AuctionNewPage.select_auction_type(:forward_fixed)
    AuctionNewPage.select_port(port.id)
    AuctionNewPage.fill_form(params)
    AuctionNewPage.add_vessels([selected_vessel])
    AuctionNewPage.add_fuel(selected_fuel.id)

    assert AuctionNewPage.credit_margin_amount() ==
             :erlang.float_to_binary(buyer_company.credit_margin_amount, decimals: 2)

    AuctionNewPage.submit()
    assert current_path() =~ ~r/auctions\/\d/

    assert AuctionShowPage.has_values_from_params?(
             Map.put(show_params, :vessels, [selected_vessel])
           )
  end

  test "creating a term auction with multiple vessels", %{
    params: params,
    show_params: show_params,
    port: port,
    selected_fuel: selected_fuel,
    buyer_company: buyer_company,
    buyer_vessels: buyer_vessels
  } do
    AuctionNewPage.visit()
    AuctionNewPage.select_auction_type(:forward_fixed)
    AuctionNewPage.select_port(port.id)
    AuctionNewPage.fill_form(params)
    AuctionNewPage.add_vessels(buyer_vessels)
    AuctionNewPage.add_fuel(selected_fuel.id)

    assert AuctionNewPage.credit_margin_amount() ==
             :erlang.float_to_binary(buyer_company.credit_margin_amount, decimals: 2)

    AuctionNewPage.submit()

    assert current_path() =~ ~r/auctions\/\d/
    assert AuctionShowPage.has_values_from_params?(show_params)
  end

  test "creating a term auction with no vessels", %{
    params: params,
    show_params: show_params,
    port: port,
    selected_fuel: selected_fuel,
    buyer_company: buyer_company
  } do
    AuctionNewPage.visit()
    AuctionNewPage.select_auction_type(:forward_fixed)
    AuctionNewPage.select_port(port.id)
    AuctionNewPage.fill_form(params)
    AuctionNewPage.add_fuel(selected_fuel.id)

    assert AuctionNewPage.credit_margin_amount() ==
             :erlang.float_to_binary(buyer_company.credit_margin_amount, decimals: 2)

    AuctionNewPage.submit()

    assert current_path() =~ ~r/auctions\/\d/
    take_screenshot()
    assert AuctionShowPage.has_values_from_params?(show_params)
  end

  test "a buyer should not be able to create a traded bid auction with no credit margin amount",
       %{
         buyer_with_no_credit: buyer_with_no_credit
       } do
    login_user(buyer_with_no_credit)
    AuctionNewPage.visit()
    AuctionNewPage.select_auction_type(:forward_fixed)
    assert_raise Hound.NoSuchElementError, fn -> AuctionNewPage.is_traded_bid_allowed() end
  end

  test "errors messages render for required fields when creating a scheduled auction", %{
    params: params,
    port: port,
    selected_fuel: selected_fuel,
    buyer_vessels: buyer_vessels
  } do
    params =
      params
      |> Map.drop([:start_date_date, :end_date_date])

    AuctionNewPage.visit()
    AuctionNewPage.select_auction_type(:forward_fixed)
    AuctionNewPage.select_port(port.id)
    AuctionNewPage.fill_form(params)
    AuctionNewPage.add_vessels(buyer_vessels)
    AuctionNewPage.add_fuel(selected_fuel.id)

    AuctionNewPage.submit()

    refute current_path() =~ ~r/auctions\/\d/
    assert AuctionNewPage.has_content?("Can't be blank")
  end
end
