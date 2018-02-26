defmodule Oceanconnect.AuctionIndexPage do
  use Oceanconnect.Page

  def visit do
    navigate_to("/auctions")
  end

  def is_current_path? do
    current_path() == "/auctions"
  end

  def start_auction(auction) do
    find_element(:class, "qa-auction-#{auction.id}")
    |> find_within_element(:class, "qa-auction-start")
    |> click
  end

  def has_auctions?(auctions) do
    auctions
    |> Enum.all?(fn(auction) ->
      case search_element(:class, "qa-auction-#{auction.id}") do
        {:ok, _} -> true
        _ -> false
      end
    end)
  end

  def auction_is_status(auction, status) do
    actual_status = find_element(:class, "qa-#{status}-auctions-list")
    |> find_within_element(:class, "qa-auction-#{auction.id}")
    |> find_within_element(:class, "qa-auction-status")
    |> inner_text()
    String.downcase(actual_status) == status
  end

  def time_remaining() do
    find_element(:css, ".qa-auction-time_remaining")
    |> Hound.Helpers.Element.inner_text
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
end
