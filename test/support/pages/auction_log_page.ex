defmodule Oceanconnect.AuctionLogPage do
  use Oceanconnect.Page

  def visit(id) do
    navigate_to("/auctions/#{id}/log")
  end

  def has_event_types?(events) do
    elements = find_all_elements(:class, "qa-event-type")
    rendered_events = Enum.map(elements, fn(element) ->
      element |> inner_text
    end)
    events == rendered_events
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
