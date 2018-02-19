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

  def time_remaining() do
    find_element(:css, ".qa-auction-time_remaining")
    |> Hound.Helpers.Element.inner_text
  end
end
