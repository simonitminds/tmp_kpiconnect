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

  def has_bid_message?(message) do
    text = find_element(:class, "qa-auction-bid-status")
    |> inner_text()
    text == message
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

  def has_bid_list_bids?(bid_list) do
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

  def winning_bid_amount() do
    find_element(:css, ".qa-winning-bid-amount")
    |> inner_text
  end

  def auction_bid_status() do
    find_element(:css, ".qa-supplier-bid-status-message")
    |> inner_text
  end

  def select_bid(bid_id) do
    find_element(:css, ".qa-select-bid-#{bid_id}")
    |> click
  end

  def accept_bid() do
    find_element(:css, ".qa-accept-bid")
    |> click
  end

  def enter_bid_comment(comment) do
    fill_field({:css, ".qa-bid-comment"}, comment)
  end

  def bid_comment() do
    find_element(:css, ".qa-bid-comment")
    |> inner_text
  end

  def enter_port_agent(name) do
    fill_field({:css, ".qa-auction-port_agent"}, name)
  end

  def port_agent() do
    find_element(:css, ".qa-port_agent")
    |> inner_text
  end

  def has_available_barge?(%Oceanconnect.Auctions.Barge{name: name, imo_number: imo_number}) do
    "#{name} (#{imo_number})" in find_element(:css, ".qa-barge-header") |> inner_text
  end
end
