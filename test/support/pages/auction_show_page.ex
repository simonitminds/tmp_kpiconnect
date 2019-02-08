defmodule Oceanconnect.AuctionShowPage do
  use Oceanconnect.Page

  import Oceanconnect.Auctions.Guards

  alias Oceanconnect.Auctions.Auction

  def visit(id) do
    navigate_to("/auctions/#{id}")
  end

  def is_current_path?(id) do
    current_path() == "/auctions/#{id}"
  end

  def view_auction_fixtures do
    find_element(:class, "qa-admin-fixtures-link") |> click
  end

  def auction_status() do
    find_element(:class, "qa-auction-status")
    |> inner_text()
  end

  def has_bid_message?(message) do
    text =
      find_element(:class, "qa-auction-bid-status")
      |> inner_text()

    text == message
  end

  def has_values_from_params?(params) do
    Enum.all?(params, fn {k, v} ->
      element = find_element(:class, "qa-auction-#{k}")
      value_equals_element_text?(k, element, v)
    end)
  end

  def has_anonymous_bidding_toggled?(_allowed = true) do
    find_element(:css, ".qa-auction-anonymous_bidding")
  end

  def has_anonymous_bidding_toggled?(_allowed = false) do
    {:error, _error} = search_element(:css, ".qa-auction-anonymous_bidding")
  end

  defp value_equals_element_text?(:suppliers, element, suppliers) when is_list(suppliers) do
    Enum.all?(suppliers, fn supplier ->
      text =
        find_within_element(element, :css, ".qa-auction-supplier-#{supplier.id}-name")
        |> inner_text

      supplier.name == text
    end)
  end

  defp value_equals_element_text?(:vessels, element, vessels) when is_list(vessels) do
    Enum.all?(vessels, fn vessel ->
      text =
        find_within_element(element, :css, ".qa-auction-vessel-#{vessel.id}")
        |> inner_text

      "#{vessel.name} (#{vessel.imo})" == text
    end)
  end

  defp value_equals_element_text?(_key, element, value) do
    text = element |> inner_text
    value == text
  end

  def bid_list_has_bids?(company_type, bid_list) do
    Enum.all?(bid_list, fn bid ->
      element =
        :css
        |> find_element(".qa-#{company_type}-bid-history")
        |> find_within_element(:css, ".qa-auction-bid-#{bid["id"]}")

      Enum.all?(bid["data"], fn {k, v} ->
        text =
          find_within_element(element, :css, ".qa-auction-bid-#{k}")
          |> inner_text

        text =~ v
      end)
    end)
  end

  def time_remaining() do
    find_element(:css, ".qa-auction-time_remaining")
    |> Hound.Helpers.Element.inner_text()
  end

  def enter_bid(params = %{}) do
    params
    |> Enum.map(fn {key, value} ->
      element = find_element(:css, "input.qa-auction-bid-#{key}")
      type = Hound.Helpers.Element.tag_name(element)
      fill_form_element(key, element, type, value)
    end)
  end

  def mark_as_traded_bid do
    find_element(:css, ".qa-auction-bid-is_traded_bid")
    |> click()
  end

  def mark_as_do_not_split do
    find_element(:css, ".qa-auction-bid-allow_split")
    |> click()
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
    |> click()
  end

  def revoke_bid_for_product(product_id) do
    execute_script(
      "document.getElementsByClassName('qa-auction-product-#{product_id}-revoke')[0].click();",
      []
    )

    Hound.Helpers.Dialog.accept_dialog()
  end

  def winning_bid_amount() do
    find_element(:css, ".qa-winning-bid-amount")
    |> inner_text()
  end

  def auction_bid_status() do
    find_element(:css, ".qa-supplier-bid-status-message")
    |> inner_text()
  end

  def select_bid(bid_id) do
    find_element(:css, ".qa-select-bid-#{bid_id}")
    |> click()
  end

  def expand_solution(solution) when is_atom(solution) do
    find_element(:css, ".qa-auction-solution-#{solution}")
    |> find_within_element(:css, ".qa-auction-solution-expand")
    |> click()
  end

  def expand_solution(index) when is_integer(index) do
    find_element(:css, ".qa-auction-other-solutions")
    |> find_all_within_element(:css, ".qa-auction-other-solution")
    |> Enum.at(index)
    |> find_within_element(:css, ".qa-auction-solution-expand")
    |> click()
  end

  def select_solution(solution) when is_atom(solution) do
    find_element(:css, ".qa-auction-solution-#{solution}")
    |> find_within_element(:css, ".qa-auction-select-solution")
    |> click()
  end

  def select_solution(index) when is_integer(index) do
    find_element(:css, ".qa-auction-other-solutions")
    |> find_all_within_element(:css, ".qa-auction-other-solution")
    |> Enum.at(index)
    |> find_within_element(:css, ".qa-auction-select-solution")
    |> click()
  end

  def select_custom_solution_bids(bids, container \\ ".qa-auction-solution-custom") do
    container = find_element(:css, container)

    Enum.each(bids, fn %{vessel_fuel_id: vfid, id: bid_id} ->
      selector =
        container
        |> find_within_element(:css, ".qa-custom-bid-selector-#{vfid} .select")

      selector
      |> click()

      container
      |> find_within_element(:css, ".qa-bid-#{bid_id}")
      |> click()
    end)
  end

  def solution_has_bids?(solution, bids) when is_atom(solution) do
    element = find_element(:css, ".qa-auction-solution-best_overall")

    Enum.all?(bids, fn bid ->
      find_within_element(element, :css, ".qa-auction-bid-#{bid.id}")
    end)
  end

  def solution_has_bids?(index, bids) when is_integer(index) do
    element =
      find_element(:css, ".qa-auction-other-solutions")
      |> find_all_within_element(:css, ".qa-auction-other-solution")
      |> Enum.at(index)

    Enum.all?(bids, fn bid ->
      find_within_element(element, :css, ".qa-auction-bid-#{bid.id}")
    end)
  end

  def winning_solution_has_bids?(bids) do
    element = find_element(:css, ".qa-auction-winning-solution")

    Enum.all?(bids, fn bid ->
      find_within_element(element, :css, ".qa-auction-bid-#{bid.id}")
    end)
  end

  def accept_bid() do
    find_element(:css, ".qa-accept-bid")
    |> click()
  end

  def enter_solution_comment(comment) do
    fill_field({:css, ".qa-solution-comment"}, comment)
  end

  def solution_comment() do
    find_element(:css, ".qa-solution-comment")
    |> inner_text
  end

  def enter_port_agent(name) do
    fill_field({:css, ".qa-auction-port_agent"}, name)
  end

  def port_agent() do
    find_element(:css, ".qa-port_agent")
    |> inner_text
  end

  def expand_barging_section() do
    find_element(:css, ".qa-barging") |> find_within_element(:tag, "section") |> click
  end

  def convert_to_supplier_names(bid_list, auction = %struct{}) when is_auction(struct) do
    Enum.map(bid_list, fn bid ->
      supplier_name = get_name_or_alias(bid.supplier_id, auction)

      bid
      |> Map.drop([:__struct__, :supplier_id])
      |> Map.put(:supplier, supplier_name)
    end)
  end

  def supplier_bid_list(bid_list, supplier_id) do
    Enum.filter(bid_list, fn bid -> bid.supplier_id == supplier_id end)
  end

  def has_available_barge?(%Oceanconnect.Auctions.Barge{name: name, imo_number: imo_number}) do
    available_barges =
      find_element(:css, ".qa-available-barges")
      |> find_all_within_element(:css, ".qa-barge-header")
      |> Enum.map(&inner_text/1)
      |> Enum.map(&String.trim/1)

    Enum.any?(available_barges, fn barge_text ->
      barge_text =~ "#{name} (#{imo_number})"
    end)
  end

  def has_submitted_barge?(%Oceanconnect.Auctions.Barge{name: name, imo_number: imo_number}) do
    submitted_barges =
      find_element(:css, ".qa-submitted-barges")
      |> find_all_within_element(:css, ".qa-barge-status-pending")
      |> Enum.map(&inner_text/1)
      |> Enum.map(&String.trim/1)

    Enum.any?(submitted_barges, fn barge_text ->
      barge_text =~ "#{name} (#{imo_number})"
    end)
  end

  def has_no_submitted_barges?, do: {:error, _} = search_element(:css, ".qa-submitted-barges")

  def has_approved_barge?(
        %Oceanconnect.Auctions.Barge{name: name, imo_number: imo_number},
        supplier_id
      ) do
    approved_barges =
      find_element(:css, ".qa-auction-supplier-#{supplier_id}-barges")
      |> find_all_within_element(:css, ".qa-barge-status-approved")
      |> Enum.map(&inner_text/1)
      |> Enum.map(&String.trim/1)

    Enum.any?(approved_barges, fn barge_text ->
      barge_text =~ "#{name} (#{imo_number})"
    end)
  end

  def has_pending_barge?(
        %Oceanconnect.Auctions.Barge{name: name, imo_number: imo_number},
        supplier_id
      ) do
    pending_barges =
      find_element(:css, ".qa-auction-supplier-#{supplier_id}-barges")
      |> find_all_within_element(:css, ".qa-barge-status-pending")
      |> Enum.map(&inner_text/1)
      |> Enum.map(&String.trim/1)

    Enum.any?(pending_barges, fn barge_text ->
      barge_text =~ "#{name} (#{imo_number})"
    end)
  end

  def has_rejected_barge?(
        %Oceanconnect.Auctions.Barge{name: name, imo_number: imo_number},
        supplier_id
      ) do
    rejected_barges =
      find_element(:css, ".qa-auction-supplier-#{supplier_id}-barges")
      |> find_all_within_element(:css, ".qa-barge-status-rejected")
      |> Enum.map(&inner_text/1)
      |> Enum.map(&String.trim/1)

    Enum.any?(rejected_barges, fn barge_text ->
      barge_text =~ "#{name} (#{imo_number})"
    end)
  end

  def submit_barge(%Oceanconnect.Auctions.Barge{id: id}) do
    find_element(:css, ".qa-barge-#{id}")
    |> find_within_element(:css, ".qa-barge-header")
    |> click

    find_element(:css, ".qa-auction-barge-submit-#{id}")
    |> click
  end

  def unsubmit_barge(%Oceanconnect.Auctions.Barge{id: id}) do
    find_element(:css, ".qa-barge-#{id}")
    |> find_within_element(:css, ".qa-barge-header")
    |> click

    find_element(:css, ".qa-auction-barge-unsubmit-#{id}")
    |> click
  end

  def approve_barge(%Oceanconnect.Auctions.Barge{id: id}, _supplier_id) do
    find_element(:css, ".qa-barge-#{id}")
    |> find_within_element(:css, ".qa-barge-header")
    |> click

    find_element(:css, ".qa-auction-barge-approve-#{id}")
    |> click
  end

  def reject_barge(%Oceanconnect.Auctions.Barge{id: id}, _supplier_id) do
    find_element(:css, ".qa-barge-#{id}")
    |> find_within_element(:css, ".qa-barge-header")
    |> click

    find_element(:css, ".qa-auction-barge-reject-#{id}")
    |> click
  end

  def expand_supplier_barges(supplier_id) do
    find_element(:css, ".qa-auction-supplier-#{supplier_id}")
    |> find_within_element(:css, ".qa-open-barges-list")
    |> click
  end

  def open_message_window do
    find_element(:css, ".qa-auction-message")
    |> click()
  end

  def has_participating_auctions?(auctions) do
    Enum.all?(auctions, fn auction ->
      text =
        find_element(:css, ".qa-auction-message-auctions")
        |> find_within_element(:css, ".qa-auction-message-auction-#{auction.id}")
        |> inner_text

      text =~ auction.vessel.name
    end)
  end

  defp get_name_or_alias(supplier_id, %struct{anonymous_bidding: true, suppliers: suppliers}) when is_auction(struct) do
    hd(Enum.filter(suppliers, &(&1.id == supplier_id))).alias_name
  end

  defp get_name_or_alias(supplier_id, %struct{suppliers: suppliers}) when is_auction(struct) do
    hd(Enum.filter(suppliers, &(&1.id == supplier_id))).name
  end
end
