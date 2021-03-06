defmodule Oceanconnect.AuctionLogPage do
  use Oceanconnect.Page
  import ExUnit.Assertions

  alias OceanconnectWeb.AuctionView

  def visit(id) do
    navigate_to("/auctions/#{id}/log")
  end

  def has_events?(events) do
    Enum.all?(events, fn event ->
      element = find_element(:class, "qa-event-#{event.id}")

      assert find_within_element(element, :class, "qa-event-type") |> inner_text =~
               AuctionView.convert_event_type(event.type)
    end)
  end

  def event_of_type_logged?(event_type) when is_atom(event_type) do
    has_content?(Atom.to_string(event_type))
  end

  def event_of_type_logged?(event_type) when is_binary(event_type) do
    has_content?(event_type)
  end

  def bid_has_supplier_as_user?(events, supplier) do
    bid_event =
      events
      |> Enum.filter(fn event -> event.type == :bid_placed end)
      |> hd

    user_text(bid_event.id) =~ "#{supplier.first_name} #{supplier.last_name}"
  end

  def event_user_displayed?(events) do
    Enum.all?(events, fn event ->
      has_user?(event)
    end)
  end

  defp has_user?(event = %{user: nil}) do
    user_text(event.id) =~ "-"
  end

  defp has_user?(event = %{user: user}) do
    user_text(event.id) =~ "#{user.first_name} #{user.last_name}"
  end

  defp has_user?(event) do
    user_text(event.id) =~ "-"
  end

  defp user_text(event_id) do
    :class
    |> find_element("qa-event-#{event_id}")
    |> find_within_element(:class, "qa-event-user")
    |> inner_text
  end

  def has_details?(details) do
    Enum.all?(details, fn {k, v} ->
      v =
        case v do
          [_] -> Enum.join(v)
          _ -> v
        end

      text =
        :class
        |> find_element("qa-auction-detail-#{k}")
        |> inner_text

      text =~ v
    end)
  end

  def has_message_details?(message_id, details) do
    message_element = find_element(:class, "qa-message-#{message_id}")

    Enum.all?(details, fn {k, v} ->
      v =
        case v do
          [_] -> Enum.join(v)
          _ -> v
        end

      text =
        message_element
        |> find_within_element(:class, "qa-message-#{k}")
        |> inner_text

      text =~ v
    end)
  end

  def has_vessel_fuel?(%{id: id, vessel: vessel, fuel: fuel, quantity: quantity}) do
    deliverable_text =
      find_element(:css, ".qa-auction-deliverable-#{id}")
      |> inner_text

    deliverable_text =~ vessel.name && deliverable_text =~ "#{vessel.imo}" &&
      deliverable_text =~ "#{quantity}" && deliverable_text =~ fuel.name
  end
end
