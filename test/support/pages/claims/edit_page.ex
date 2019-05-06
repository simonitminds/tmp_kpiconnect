defmodule Oceanconnect.Claims.EditPage do
  use Oceanconnect.Page

  def visit(auction_id, claim_id) do
    navigate_to("/auctions/#{auction_id}/claims/#{claim_id}/edit")
  end

  def is_current_path?(auction_id, claim_id) do
    current_path() == "/auctions/#{auction_id}/claims/#{claim_id}/edit"
  end

  def place_notice(recipient) do
    click({:css, ".qa-claim-place_notice-#{recipient}"})
  end

  def enter_response(response) do
    fill_field(
      {:css, ".qa-claim-response"},
      response
    )
  end

  def update_claim do
    click({:css, ".qa-claim-update"})
  end

  def close_claim(claim_resolution) do
    click({:css, ".qa-claim-close"})
    fill_field({:css, ".qa-claim-claim_resolution"})
  end
end
