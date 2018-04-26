defmodule Oceanconnect.AuctionLogPage do
  use Oceanconnect.Page
  alias OceanconnectWeb.AuctionView

  def visit(id) do
    navigate_to("/auctions/#{id}/log")
  end

  def has_events?(events) do
    Enum.all?(events, fn(event) ->
      element = find_element(:class, "qa-event-#{event.id}")
      with true <- Atom.to_string(event.type) == element |> find_within_element(:class, "qa-event-type") |> inner_text,
           true <- AuctionView.event_company(event) == element |> find_within_element(:class, "qa-event-company") |> inner_text,
           true <- AuctionView.event_bid_amount(event) == element |> find_within_element(:class, "qa-event-bid-amount") |> inner_text,
           do: true
    end)
  end

  def has_details?(details) do
    Enum.all?(details, fn({k, v}) ->
      text = :class
      |> find_element("qa-auction-detail-#{k}")
      |> inner_text
      text == v
    end)
  end
end
