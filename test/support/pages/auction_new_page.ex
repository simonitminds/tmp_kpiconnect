defmodule Oceanconnect.AuctionNewPage do
  @page_path "/auctions/new"
  use Oceanconnect.Page

  alias Oceanconnect.Auctions.{Fuel, Vessel}

  def visit do
    navigate_to(@page_path)
  end

  def has_fields?(fields) do
    Enum.all?(fields, fn field ->
      find_element(:css, ".qa-auction-#{field}")
    end)
  end

  def buyer_vessels_in_vessel_list?(vessels) do
    element = find_element(:css, ".qa-auction-select-vessel")
    Enum.all?(vessels, fn vessel ->
      find_within_element(element, :id, "#{vessel.id}")
    end)
  end

  def fill_form(params = %{}) do
    params
    |> Enum.map(fn {key, value} ->
      element = find_element(:css, ".qa-auction-#{key}")
      type = Hound.Helpers.Element.tag_name(element)
      fill_form_element(element, type, value)
    end)
  end

  def fill_form_element(element, _type, value = %DateTime{}) do
    element
    |> find_within_element(:css, "input")
    |> fill_field(value)
  end

  def fill_form_element(_element, _type, value) when is_list(value) do
    Enum.map(value, fn supplier ->
      execute_script("document.getElementById('invite-#{supplier.id}').click();", [])
    end)
  end

  def fill_form_element(element, "select", value) do
    find_within_element(element, :css, "option[value='#{value}']")
    |> click
  end

  def fill_form_element(element, "checkbox", value) do
    if value == true do
      click(element)
    end
  end

  def fill_form_element(element, _type, value) when is_boolean(value) do
    if value == true do
      click(element)
    end
  end

  def fill_form_element(element, _type, value) do
    fill_field(element, value)
  end

  def add_vessels(vessels) do
    Enum.each(vessels, fn vessel ->
      find_element(:css, ".qa-auction-select-vessel")
      |> fill_form_element("select", vessel.id)
    end)
  end

  def add_fuel(fuel_id) do
    find_element(:css, ".qa-auction-select-fuel")
    |> fill_form_element("select", fuel_id)
  end

  def add_vessels_fuel_quantity(fuel_id, vessels, fuel_quantity) do
    Enum.each(vessels, fn vessel ->
      find_element(:css, ".qa-auction-vessel-#{vessel.id}-fuel-#{fuel_id}-quantity")
      |> fill_form_element("input", fuel_quantity)
    end)
  end

  # def add_vessel_fuel(index, selected_vessel = %Vessel{}, selected_fuel = %Fuel{}, quantity) do
  #   find_element(:css, ".qa-auction-vessel_fuel-#{index}-vessel_id")
  #   |> fill_form_element("select", selected_vessel.id)

  #   find_element(:css, ".qa-auction-vessel_fuel-#{index}-fuel_id")
  #   |> fill_form_element("select", selected_fuel.id)

  #   find_element(:css, ".qa-auction-vessel_fuel-#{index}-quantity")
  #   |> fill_form_element("input", quantity)
  # end

  def select_port(port_id) do
    find_element(:css, ".qa-auction-port_id option[value='#{port_id}']")
    |> click
  end

  def disable_split_bidding() do
    find_element(:css, ".qa-auction-split_bid_allowed")
    |> click
  end

  def has_suppliers?(suppliers) do
    Enum.all?(suppliers, fn supplier ->
      find_element(:css, ".qa-auction-supplier-#{supplier.id}")
    end)
  end

  def supplier_count(suppliers) do
    Enum.map(suppliers, fn supplier ->
      find_element(:css, ".qa-auction-supplier-#{supplier.id}")
    end)
    |> length
  end

  def credit_margin_amount do
    find_element(:css, ".qa-auction-credit_margin_amount")
    |> inner_text
  end

  def is_traded_bid_allowed do
    find_element(:css, ".qa-auction-is_traded_bid_allowed")
  end

  def submit do
    submit_element({:css, ".qa-auction-submit"})
  end
end
