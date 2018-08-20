defmodule Oceanconnect.AuctionNewTest do
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
    buyer_vessels = insert_list(3, :vessel, company: buyer_company)
    insert(:vessel)
    supplier_companies = insert_list(3, :company, is_supplier: true)

    port =
      insert(:port, companies: [buyer_company, buyer_company_with_no_credit] ++ supplier_companies)

    selected_vessel = hd(buyer_vessels)
    selected_company1 = Enum.at(supplier_companies, 0)
    selected_company2 = Enum.at(supplier_companies, 2)

    date_time = DateTime.utc_now()
    suppliers = [selected_company1, selected_company2]

    auction_params = %{
      anonymous_bidding: true,
      decision_duration: 15,
      duration: 10,
      eta_date: date_time,
      eta_time: date_time,
      etd_date: date_time,
      etd_time: date_time,
      is_traded_bid_allowed: true,
      scheduled_start_date: date_time,
      scheduled_start_time: date_time,
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
      vessel: "#{selected_vessel.name} (#{selected_vessel.imo})",
      port: port.name,
      suppliers: suppliers
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
       selected_vessel: selected_vessel
     }}
  end

  test "visting the new auction page" do
    AuctionNewPage.visit()

    assert AuctionNewPage.has_fields?([
             "additional_information",
             "anonymous_bidding",
             "scheduled_start",
             "duration",
             "decision_duration",
             "eta",
             "etd",
             "is_traded_bid_allowed",
             "po",
             "port_id",
             "select-port"
           ])
  end

  test "vessels list is filtered by buyer company", %{buyer_vessels: buyer_vessels} do
    AuctionNewPage.visit()
    buyer_vessels = Enum.map(buyer_vessels, fn v -> "#{v.name}, #{v.imo}" end)
    vessels_on_page = MapSet.new(AuctionNewPage.vessel_list())
    company_vessels = MapSet.new(buyer_vessels)

    assert MapSet.equal?(vessels_on_page, company_vessels)
  end

  test "port selection reveals port agent and supplier list", %{port: port} do
    AuctionNewPage.visit()
    AuctionNewPage.select_port(port.id)

    assert AuctionNewPage.has_fields?([
             "port_agent",
             "suppliers"
           ])
  end

  test "supplier list is filtered by port", %{suppliers: suppliers, port: port} do
    AuctionNewPage.visit()
    AuctionNewPage.select_port(port.id)

    assert AuctionNewPage.has_suppliers?(suppliers)
    assert AuctionNewPage.supplier_count(suppliers) == 2
  end

  test "creating an auction with one vessel fuel", %{
    params: params,
    show_params: show_params,
    port: port,
    selected_vessel: selected_vessel,
    fuels: [selected_fuel | _rest]
  } do
    AuctionNewPage.visit()
    AuctionNewPage.select_port(port.id)
    AuctionNewPage.fill_form(Map.put(params, :is_traded_bid_allowed, true))
    AuctionNewPage.add_vessel_fuel(0, selected_vessel, selected_fuel, 1500)
    AuctionNewPage.submit()

    assert current_path() =~ ~r/auctions\/\d/
    assert AuctionShowPage.has_values_from_params?(show_params)
    assert AuctionNewPage.credit_margin_amount() ==
             :erlang.float_to_binary(buyer_company.credit_margin_amount, decimals: 2)
  end

  test "creating an auction with multiple vessel fuels", %{
    params: params,
    show_params: show_params,
    port: port,
    buyer_vessels: [vessel1 | _],
    fuels: [fuel1, fuel2 | _]
  } do
    AuctionNewPage.visit()
    AuctionNewPage.select_port(port.id)
    AuctionNewPage.fill_form(params)
    AuctionNewPage.add_vessel_fuel(0, vessel1, fuel1, 1500)
    AuctionNewPage.add_vessel_fuel(1, vessel1, fuel2, 2000)
    AuctionNewPage.submit()

    assert current_path() =~ ~r/auctions\/\d/
    assert AuctionShowPage.has_values_from_params?(show_params)
  end

  test "creating an auction with split bidding disabled", %{
    params: params,
    show_params: show_params,
    port: port,
    buyer_vessels: [vessel1 | _],
    fuels: [fuel1, fuel2 | _]
  } do
    AuctionNewPage.visit()
    AuctionNewPage.select_port(port.id)
    AuctionNewPage.fill_form(params)
    AuctionNewPage.add_vessel_fuel(0, vessel1, fuel1, 1500)
    AuctionNewPage.add_vessel_fuel(1, vessel1, fuel2, 2000)
    AuctionNewPage.disable_split_bidding()
    AuctionNewPage.submit()

    assert current_path() =~ ~r/auctions\/\d/
    assert AuctionShowPage.has_split_bidding_toggled?(true)
  end

  test "a buyer should not be able to create a traded bid auction with no credit margin amount",
       %{
         buyer_with_no_credit: buyer_with_no_credit
       } do
    login_user(buyer_with_no_credit)
    AuctionNewPage.visit()
    assert_raise Hound.NoSuchElementError, fn -> AuctionNewPage.is_traded_bid_allowed() end
  end
end
