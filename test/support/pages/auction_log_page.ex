defmodule Oceanconnect.AuctionLogPage do
  use Oceanconnect.Page
  alias OceanconnectWeb.AuctionView

  def visit(id) do
    navigate_to("/auctions/#{id}/log")
  end

  def has_events?(events) do
    Enum.all?(events, fn event ->
      element = find_element(:class, "qa-event-#{event.id}")

      with true <-
             AuctionView.convert_event_type(event.type) ==
               element |> find_within_element(:class, "qa-event-type") |> inner_text,
           true <-
             AuctionView.event_company(event) ==
               element |> find_within_element(:class, "qa-event-company") |> inner_text,
           true <-
             AuctionView.event_bid_amount(event) ==
               element |> find_within_element(:class, "qa-event-bid-amount") |> inner_text,
           do: true
    end)
  end

  def bid_has_supplier_as_user?(events, supplier) do
    bid_event =
      events
      |> Enum.filter(fn event -> event.type == :bid_placed end)
      |> hd

    user_text(bid_event.id) == "#{supplier.first_name} #{supplier.last_name}"
  end

  def event_user_displayed?(events) do
    Enum.all?(events, fn event ->
      has_user?(event)
    end)
  end

  defp has_user?(event = %{user: nil}) do
    user_text(event.id) == "-"
  end

  defp has_user?(event = %{user: user}) do
    user_text(event.id) == "#{user.first_name} #{user.last_name}"
  end

  defp has_user?(event) do
    user_text(event.id) == "-"
  end

  defp user_text(event_id) do
    :class
    |> find_element("qa-event-#{event_id}")
    |> find_within_element(:class, "qa-event-user")
    |> inner_text
  end

  def has_details?(details) do
    Enum.all?(details, fn {k, v} ->
      text =
        :class
        |> find_element("qa-auction-detail-#{k}")
        |> inner_text

      text == v
    end)
  end
end
