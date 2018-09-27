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

  def vessel_list() do
    find_all_elements(:css, ".qa-auction-vessel_id option")
    |> Enum.map(fn elem -> inner_text(elem) end)
    |> Enum.reject(fn elem -> elem == "Please select" end)
  end

  def fill_form(params = %{}) do
    params
    |> Enum.map(fn {key, value} ->
      element = find_element(:css, ".qa-auction-#{key}")
      type = Hound.Helpers.Element.tag_name(element)
      fill_form_element(key, element, type, value)
    end)
  end

  def fill_form_element(_key, element, _type, value = %DateTime{}) do
    element
    |> find_within_element(:css, "input")
    |> fill_field(value)
  end

  def fill_form_element(_key, _element, _type, value) when is_list(value) do
    Enum.map(value, fn supplier ->
      execute_script("document.getElementById('invite-#{supplier.id}').click();", [])
    end)
  end

  def fill_form_element(_key, element, "select", value) do
    find_within_element(element, :css, "option[value='#{value}']")
    |> click
  end

  def fill_form_element(_key, element, _type, value) do
    input_into_field(element, value)
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
    element =
      find_element(:css, ".qa-auction-credit_margin_amount")
      |> inner_text
  end

  def submit do
    submit_element({:css, ".qa-auction-submit"})
  end
end
