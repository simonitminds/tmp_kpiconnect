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
    |> Enum.all?(fn auction ->
      case search_element(:class, "qa-auction-#{auction.id}") do
        {:ok, _} -> true
        _ -> false
      end
    end)
  end

  def cancel_auction(auction) do
    find_element(:class, "qa-auction-#{auction.id}")
    |> find_within_element(:class, "qa-auction-cancel")
    |> click

    Hound.Helpers.Dialog.accept_dialog()
  end

  def auction_is_status?(auction, status) do
    actual_status =
      find_element(:class, "qa-#{status}-auctions-list")
      |> find_within_element(:class, "qa-auction-#{auction.id}")
      |> find_within_element(:class, "qa-auction-status")
      |> inner_text()

    String.downcase(actual_status) == status
  end

  def time_remaining() do
    find_element(:css, ".qa-auction-time_remaining")
    |> Hound.Helpers.Element.inner_text()
  end

  def has_values_from_params?(params) do
    Enum.all?(params, fn {k, v} ->
      element = find_element(:class, "qa-auction-#{k}")
      value_equals_element_text?(k, element, v)
    end)
  end

  defp value_equals_element_text?(_key, element, value) do
    value == element |> inner_text
  end

  def has_field_in_auction?(auction_id, field) do
    element = find_element(:class, "qa-auction-#{auction_id}")

    case search_within_element(element, :class, "qa-auction-#{field}") do
      {:ok, _} -> true
      {:error, _} -> false
    end
  end

  def open_messaging_window do
    find_element(:css, ".qa-auction-messaging")
    |> click()
  end

  def has_participating_auctions?(auctions) do
    Enum.all?(auctions, fn auction ->
      text = find_element(:css, ".qa-auction-messaging-auctions")
      |> find_within_element(:css, ".qa-auction-messaging-auction-#{auction.id}")
      |> inner_text

      text =~ auction.vessel.name
    end)
  end
end
