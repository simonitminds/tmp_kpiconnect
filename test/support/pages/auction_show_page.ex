defmodule Oceanconnect.AuctionShowPage do
  use Oceanconnect.Page

  def visit(id) do
    navigate_to("/auctions/#{id}")
  end

  def is_current_path?(id) do
    current_path() == "/auctions/#{id}"
  end

  def auction_status() do
    find_element(:class, "qa-auction-status")
    |> inner_text()
  end

  def has_values_from_params?(params) do
    Enum.all?(params, fn({k, v}) ->
      element = find_element(:class, "qa-auction-#{k}")
      value_equals_element_text?(k, element, v)
    end)
  end

  defp value_equals_element_text?(:suppliers, element, suppliers) when is_list(suppliers) do
    Enum.all?(suppliers, fn(supplier) ->
      text = find_within_element(element, :css, ".qa-auction-supplier-#{supplier.id}")
      |> inner_text
      supplier.name == text
    end)
  end
  defp value_equals_element_text?(_key, element, value) do
    value == element |> inner_text
  end

  def has_buyer_bids?(bid_list) do
    Enum.all?(bid_list, fn(bid) ->
      element = find_element(:class, "qa-auction-bid-#{bid["id"]}")
      Enum.all?(bid["data"], fn({k, v}) ->
        text = find_within_element(element, :css, ".qa-auction-bid-#{k}")
        |> inner_text
        v == text
      end)
    end)
  end

  def time_remaining() do
    find_element(:css, ".qa-auction-time_remaining")
    |> Hound.Helpers.Element.inner_text
  end

  def enter_bid(params = %{}) do
    params
    |> Enum.map(fn({key, value}) ->
      element = find_element(:class, "qa-auction-bid-#{key}")
      type = Hound.Helpers.Element.tag_name(element)
      fill_form_element(key, element, type, value)
    end)
  end

  def fill_form_element(:additional_charges, element, _type, _value) do
    element |> click
  end
  def fill_form_element(_key, element, "select", value) do
    find_within_element(element, :css, "option[value='#{value}']")
    |> click
  end
  def fill_form_element(_key, element, _type, value) do
    fill_field(element, value)
  end

  def submit_bid() do
    find_element(:css, ".qa-auction-bid-submit")
    |> click
  end
end
