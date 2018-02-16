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
      text = find_element(:class, "qa-auction-#{k}")
      |> inner_text
      text == v
    end)
  end

  def time_remaining() do
    find_element(:css, ".qa-auction-time_remaining")
    |> Hound.Helpers.Element.inner_text
  end
end
