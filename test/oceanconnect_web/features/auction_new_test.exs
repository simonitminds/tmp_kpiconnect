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
      decision_duration: 15,
      duration: 10,
      is_traded_bid_allowed: true,
      scheduled_start_date: valid_start_time,
      scheduled_start_time: valid_start_time,
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
      vessels: buyer_vessels,
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
       selected_vessel: selected_vessel,
       date_time: date_time
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
             "is_traded_bid_allowed",
             "po",
             "port_id",
             "select-fuel",
             "select-port",
             "select-vessel"
           ])
  end

  test "vessels list is filtered by buyer company", %{buyer_vessels: buyer_vessels} do
    AuctionNewPage.visit()
    assert AuctionNewPage.buyer_vessels_in_vessel_list?(buyer_vessels)
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

  test "creating an auction with one vessel fuel and one vessel", %{
    params: params,
    show_params: show_params,
    port: port,
    fuels: [selected_fuel | _rest],
    buyer_company: buyer_company,
    buyer_vessels: [selected_vessel | _reset],
    date_time: date_time
  } do
    AuctionNewPage.visit()
    AuctionNewPage.select_port(port.id)
    AuctionNewPage.fill_form(params)
    AuctionNewPage.add_vessels([selected_vessel])
    AuctionNewPage.add_vessel_timestamps([selected_vessel], date_time, date_time)
    AuctionNewPage.add_fuel(selected_fuel.id)
    AuctionNewPage.add_vessels_fuel_quantity(selected_fuel.id, [selected_vessel], 1500)

    assert AuctionNewPage.credit_margin_amount() ==
             :erlang.float_to_binary(buyer_company.credit_margin_amount, decimals: 2)

    AuctionNewPage.submit()
    assert current_path() =~ ~r/auctions\/\d/

    assert AuctionShowPage.has_values_from_params?(
             Map.put(show_params, :vessels, [selected_vessel])
           )
  end

  test "creating an auction with one vessel fuel and multiple vessels", %{
    params: params,
    show_params: show_params,
    port: port,
    fuels: [selected_fuel | _rest],
    date_time: date_time,
    buyer_company: buyer_company,
    buyer_vessels: buyer_vessels
  } do
    AuctionNewPage.visit()
    AuctionNewPage.select_port(port.id)
    AuctionNewPage.fill_form(params)
    AuctionNewPage.add_vessels(buyer_vessels)
    AuctionNewPage.add_vessel_timestamps(buyer_vessels, date_time, date_time)
    AuctionNewPage.add_fuel(selected_fuel.id)
    AuctionNewPage.add_vessels_fuel_quantity(selected_fuel.id, buyer_vessels, 1500)

    assert AuctionNewPage.credit_margin_amount() ==
             :erlang.float_to_binary(buyer_company.credit_margin_amount, decimals: 2)

    AuctionNewPage.submit()

    assert current_path() =~ ~r/auctions\/\d/
    assert AuctionShowPage.has_values_from_params?(show_params)
  end

  test "creating an auction with multiple vessel fuels", %{
    params: params,
    show_params: show_params,
    port: port,
    buyer_vessels: buyer_vessels,
    date_time: date_time,
    fuels: fuels
  } do
    AuctionNewPage.visit()
    AuctionNewPage.select_port(port.id)
    AuctionNewPage.fill_form(params)
    AuctionNewPage.add_vessels(buyer_vessels)
    AuctionNewPage.add_vessel_timestamps(buyer_vessels, date_time, date_time)

    Enum.each(fuels, fn fuel ->
      AuctionNewPage.add_fuel(fuel.id)
      AuctionNewPage.add_vessels_fuel_quantity(fuel.id, buyer_vessels, 1500)
    end)

    AuctionNewPage.submit()

    assert current_path() =~ ~r/auctions\/\d/
    assert AuctionShowPage.has_values_from_params?(show_params)
  end

  test "creating an auction with split bidding disabled", %{
    params: params,
    show_params: show_params,
    port: port,
    buyer_vessels: buyer_vessels,
    date_time: date_time,
    fuels: fuels
  } do
    AuctionNewPage.visit()
    AuctionNewPage.select_port(port.id)
    AuctionNewPage.fill_form(params)
    AuctionNewPage.add_vessels(buyer_vessels)
    AuctionNewPage.add_vessel_timestamps(buyer_vessels, date_time, date_time)

    Enum.each(fuels, fn fuel ->
      AuctionNewPage.add_fuel(fuel.id)
      AuctionNewPage.add_vessels_fuel_quantity(fuel.id, buyer_vessels, 1500)
    end)

    AuctionNewPage.submit()

    assert current_path() =~ ~r/auctions\/\d/
    assert AuctionShowPage.has_values_from_params?(show_params)
  end

  test "a buyer should not be able to create a traded bid auction with no credit margin amount",
       %{
         buyer_with_no_credit: buyer_with_no_credit
       } do
    login_user(buyer_with_no_credit)
    AuctionNewPage.visit()
    assert_raise Hound.NoSuchElementError, fn -> AuctionNewPage.is_traded_bid_allowed() end
  end

  test "errors messages render for required fields when creating a scheduled auction", %{
    params: params,
    port: port,
    buyer_vessels: buyer_vessels,
    fuels: fuels
  } do
    AuctionNewPage.visit()
    AuctionNewPage.select_port(port.id)
    AuctionNewPage.fill_form(params)
    AuctionNewPage.add_vessels(buyer_vessels)

    Enum.each(fuels, fn fuel ->
      AuctionNewPage.add_fuel(fuel.id)
      AuctionNewPage.add_vessels_fuel_quantity(fuel.id, buyer_vessels, 1500)
    end)

    AuctionNewPage.submit()

    refute current_path() =~ ~r/auctions\/\d/

    assert AuctionNewPage.has_content?(
             "All vessels must have an ETA when the auction is scheduled."
           )
  end
end
