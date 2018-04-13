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
end
