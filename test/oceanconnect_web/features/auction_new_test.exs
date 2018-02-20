defmodule Oceanconnect.AuctionNewTest do
  use Oceanconnect.FeatureCase, async: false
  alias Oceanconnect.{AuctionNewPage, AuctionShowPage}

  hound_session()

  setup do
    buyer_company = insert(:company)
    buyer = insert(:user, company: buyer_company)
    login_user(buyer)
    fuel = insert(:fuel)
    buyer_vessels = insert_list(3, :vessel, company: buyer_company)
    insert(:vessel)
    supplier_companies = insert_list(3, :company, is_supplier: true)
    port = insert(:port, companies: [buyer_company] ++ supplier_companies)
    selected_vessel = hd(buyer_vessels)
    selected_company1 = Enum.at(supplier_companies, 0)
    selected_company2 = Enum.at(supplier_companies, 2)

    auction_params = %{
      auction_start_date: DateTime.utc_now(),
      auction_start_time: DateTime.utc_now(),
      eta_date: DateTime.utc_now(),
      eta_time: DateTime.utc_now(),
      etd_date: DateTime.utc_now(),
      etd_time: DateTime.utc_now(),
      decision_duration: 15,
      duration: 10,
      fuel_id: fuel.id,
      fuel_quantity: 1_000,
      suppliers: [
        %{
          id: selected_company1.id
        },
        %{
          id: selected_company2.id
        }
      ],
      vessel_id: selected_vessel.id
    }
    show_params = %{
      vessel: "#{selected_vessel.name} (#{selected_vessel.imo})",
      port: port.name,
      suppliers: [selected_company1, selected_company2]
    }
    {:ok, %{buyer_vessels: buyer_vessels, params: auction_params, show_params: show_params, port: port}}
  end

  test "visting the new auction page" do
    AuctionNewPage.visit()

    assert AuctionNewPage.has_fields?([
      "additional_information",
      "anonymous_bidding",
      "auction_start",
      "duration",
      "decision_duration",
      "eta",
      "etd",
      "fuel_id",
      "fuel_quantity",
      "po",
      "port_id",
      "vessel_id"
    ])
  end

  test "vessels list is filtered by buyer company", %{buyer_vessels: buyer_vessels} do
    AuctionNewPage.visit()
    buyer_vessels = Enum.map(buyer_vessels, fn(v) -> "#{v.name}, #{v.imo}" end)
    vessels_on_page = MapSet.new(AuctionNewPage.vessel_list())
    company_vessels = MapSet.new(buyer_vessels)

    assert MapSet.equal?(vessels_on_page, company_vessels)
  end

  test "creating an auction", %{params: params, show_params: show_params, port: port} do
    AuctionNewPage.visit()
    AuctionNewPage.select_port(port.id)
    AuctionNewPage.fill_form(params)
    AuctionNewPage.submit()

    eventually fn ->
      assert current_path() =~ ~r/auctions\/\d/
      assert AuctionShowPage.has_values_from_params?(show_params)
    end
  end
end
