defmodule Oceanconnect.Claims.ShowPage do
  use Oceanconnect.Page

  def visit(auction_id, claim_id) do
    navigate_to("/auctions/#{auction_id}/claims/#{claim_id}")
  end

  def is_current_path?(auction_id, claim_id) do
    current_path() == "/auctions/#{auction_id}/claims/#{claim_id}"
  end

  def has_success_message?(message) do
    has_content?(message)
  end

  def has_auction_details?(
        %{id: auction_id, vessels: vessels, port: port} = _auction,
        %{etd: etd} = _fixture
      ) do
    auction_number =
      find_element(:css, ".qa-claim-auction-auction_id")
      |> inner_text()

    auction_vessels =
      find_element(:css, ".qa-claim-auction-vessels")
      |> inner_text()

    port_name =
      find_element(:css, ".qa-claim-auction-port")
      |> inner_text()

    date_of_delivery =
      find_element(:css, ".qa-claim-fixture-etd")
      |> inner_text()

    cond do
      auction_number != "#{auction_id}" -> false
      auction_vessels != OceanconnectWeb.ClaimView.vessel_name_list(vessels) -> false
      port_name != port.name -> false
      date_of_delivery != OceanconnectWeb.ClaimView.convert_date?(etd) -> false
      true -> true
    end
  end

  def has_claim_type?(type) do
    inner_text({:css, ".qa-claim-type"}) == "#{String.capitalize(Atom.to_string(type))} Claim"
  end

  def has_receiving_vessel?(vessel_name) do
    inner_text({:css, ".qa-claim-receiving_vessel"}) == vessel_name
  end

  def has_delivered_fuel?(fuel_name) do
    inner_text({:css, ".qa-claim-delivered_fuel"}) == fuel_name
  end

  def has_delivering_barge?(barge_name) do
    inner_text({:css, ".qa-claim-delivering_barge"}) == barge_name
  end

  def has_claims_details?(claim, :quantity) do
    price_per_unit =
      claim.price_per_unit
      |> OceanconnectWeb.ClaimView.format_price()

    total_fuel_value =
      claim.total_fuel_value
      |> OceanconnectWeb.ClaimView.format_price()

    quantity_missing =
      claim.quantity_missing
      |> Decimal.to_integer()

    quantity_missing = "#{quantity_missing} M/T"

    time_submitted = OceanconnectWeb.ClaimView.convert_date?(claim.inserted_at)

    cond do
      inner_text({:css, ".qa-claim-price_per_unit"}) != price_per_unit -> false
      inner_text({:css, ".qa-claim-total_fuel_value"}) != total_fuel_value -> false
      inner_text({:css, ".qa-claim-quantity_missing"}) != quantity_missing -> false
      inner_text({:css, ".qa-claim-time_submitted"}) != time_submitted -> false
      true -> true
    end
  end

  def has_claims_details?(claim, :density) do
    price_per_unit =
      claim.price_per_unit
      |> OceanconnectWeb.ClaimView.format_price()

    total_fuel_value =
      claim.total_fuel_value
      |> OceanconnectWeb.ClaimView.format_price()

    quantity_difference =
      claim.quantity_difference
      |> Decimal.to_integer()

    quantity_difference = "#{quantity_difference} M/T"

    time_submitted = OceanconnectWeb.ClaimView.convert_date?(claim.inserted_at)

    cond do
      inner_text({:css, ".qa-claim-price_per_unit"}) != price_per_unit -> false
      inner_text({:css, ".qa-claim-total_fuel_value"}) != total_fuel_value -> false
      inner_text({:css, ".qa-claim-quantity_difference"}) != quantity_difference -> false
      inner_text({:css, ".qa-claim-time_submitted"}) != time_submitted -> false
      true -> true
    end
  end

  def has_claims_details?(claim, :quality) do
    quality_description = claim.quality_description
    time_submitted = OceanconnectWeb.ClaimView.convert_date?(claim.inserted_at)

    cond do
      inner_text({:css, ".qa-claim-quality_description"}) != quality_description -> false
      inner_text({:css, ".qa-claim-time_submitted"}) != time_submitted -> false
      true -> true
    end
  end

  def has_notice_recipient_type?(type) do
    attribute_value({:css, ".qa-claim-place_notice-#{type}"}, "checked") == "true"
  end

  def has_last_correspondence_sent?(type, last_correspondence) do
    inner_text({:css, ".qa-claim-#{type}_last_correspondence"}) ==
      OceanconnectWeb.ClaimView.convert_date?(last_correspondence)
  end

  def add_response do
    click({:css, ".qa-claim-add_response"})
  end

  def has_response?(response, content, author) do
    cond do
      inner_text({:css, ".qa-claim-response-#{response.id} .qa-response-content"}) != content ->
        false

      inner_text({:css, ".qa-claim-response-#{response.id} .qa-response-author"}) !=
          Oceanconnect.Accounts.User.full_name(author) ->
        false

      true ->
        true
    end
  end

  def claim_resolved? do
    inner_text({:css, ".qa-claim-status"}) == "Resolved"
  end

  def has_claim_resolution?(resolution) do
    inner_text({:css, ".qa-claim-claim_resolution"}) == resolution
  end
end
