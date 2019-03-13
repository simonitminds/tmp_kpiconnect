defmodule Oceanconnect.AuctionNewPage do
  @page_path "/auctions/new"
  use Oceanconnect.Page

  def visit do
    navigate_to(@page_path)
  end

  def has_fields?(fields) do
    Enum.all?(fields, fn field ->
      find_element(:css, ".qa-auction-#{field}")
    end)
  end

  def select_auction_type(type) do
    find_element(:css, ".qa-auction-type")
    |> find_within_element(:css, "option[value='#{type}']")
    |> click
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

      if key in [:start_date, :end_date, :scheduled_start_date] do
        type = Hound.Helpers.Element.tag_name(element)
        fill_form_element(element, type, value, key)
      else
        type = Hound.Helpers.Element.tag_name(element)
        fill_form_element(element, type, value)
      end
    end)
  end

  def fill_form_element(element, _type, value = %DateTime{}, key)
      when key in [:start_date, :scheduled_start_date, :end_date] do
    execute_script("document.getElementById('auction-#{key}').value = '#{value}'")
  end

  def fill_form_element(element, _type, value = %DateTime{}) do
    element
    |> find_within_element(:class, "qa-date-time-picker")
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

  def add_vessel_timestamps(vessels, eta, etd) do
    Enum.each(vessels, fn vessel ->
      container = find_element(:css, ".qa-auction-vessel-#{vessel.id}")

      container
      |> find_within_element(:css, ".qa-vessel-eta_date")
      |> fill_form_element("datetime", eta)

      container
      |> find_within_element(:css, ".qa-vessel-eta_time")
      |> fill_form_element("datetime", eta)

      container
      |> find_within_element(:css, ".qa-vessel-etd_date")
      |> fill_form_element("datetime", etd)

      container
      |> find_within_element(:css, ".qa-vessel-etd_time")
      |> fill_form_element("datetime", etd)
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

  def select_port(port_id) do
    find_element(:css, ".qa-auction-port_id option[value='#{port_id}']")
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

  def total_fuel_volume do
    click({:css, ".qa-auction-show_total_fuel_volume"})

    find_element(:css, ".qa-auction-total_fuel_volume")
    |> inner_text()
  end

  def submit do
    submit_element({:css, ".qa-auction-submit"})
  end
end
