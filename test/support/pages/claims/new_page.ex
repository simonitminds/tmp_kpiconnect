defmodule Oceanconnect.Claims.NewPage do
  use Oceanconnect.Page

  def visit(auction_id) do
    navigate_to("/auctions/#{auction_id}/claims/new")
  end

  def is_current_path?(auction_id) do
    current_path() == "/auctions/#{auction_id}/claims/new"
  end

  def select_claim_type(type) do
    click({:css, ".qa-claim-type-#{type}"})
  end

  def select_supplier(supplier_id) do
    click({:css, ".qa-claim-supplier_id option[value='#{supplier_id}']"})
  end

  def select_receiving_vessel(vessel_id) do
    click({:css, ".qa-claim-receiving_vessel_id option[value='#{vessel_id}']"})
  end

  def select_delivered_fuel(fuel_id) do
    click({:css, ".qa-claim-delivered_fuel_id option[value='#{fuel_id}']"})
  end

  def enter_quantity_missing(quantity_missing) do
    fill_field(
      {:css, ".qa-claim-quantity_missing"},
      quantity_missing
    )
  end

  def enter_quantity_difference(quantity_difference) do
    fill_field(
      {:css, ".qa-claim-quantity_difference"},
      quantity_difference
    )
  end

  def enter_price_per_unit(price_per_unit) do
    fill_field(
      {:css, ".qa-claim-price_per_unit"},
      price_per_unit
    )
  end

  def enter_total_fuel_value(total_fuel_value) do
    fill_field(
      {:css, ".qa-claim-total_fuel_value"},
      total_fuel_value
    )
  end

  def select_delivering_barge(barge_id) do
    click({:css, ".qa-claim-delivering_barge_id option[value='#{barge_id}']"})
  end

  def place_notice(recipient) do
    click({:css, ".qa-claim-place_notice-#{recipient}"})
  end

  def enter_additional_information(response) do
    fill_field(
      {:css, ".qa-claim-additional_information"},
      response
    )
  end

  def enter_quality_description(description) do
    fill_field(
      {:css, ".qa-claim-quality_description"},
      description
    )
  end

  def submit_claim do
    click({:css, ".qa-claim-submit"})
  end
end
