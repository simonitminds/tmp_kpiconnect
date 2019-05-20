defmodule Oceanconnect.Auction.HistoricalIndexPage do
  use Oceanconnect.Page

  def visit do
    navigate_to("/historical_auctions")
  end

  def is_current_path? do
    current_path() == "/historical_auctions"
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

  def filter_vessel(vessel_id) do
    click({:css, ".qa-filter-vessel_id .qa-filter-vessel_id-#{vessel_id}"})
  end

  def filter_supplier(supplier_id) do
    click({:css, ".qa-filter-supplier_id .qa-filter-supplier_id-#{supplier_id}"})
  end

  def filter_port(port_id) do
    click({:css, ".qa-filter-port_id .qa-filter-port_id-#{port_id}"})
  end

  def enter_end_time_filter(end_time) do
    fill_field({:css, ".qa-filter-endTimeRange_date input"}, end_time)
  end
end
