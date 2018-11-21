defmodule Oceanconnect.AuctionRsvpPage do
  use Oceanconnect.Page
  alias Oceanconnect.Auctions.Auction

  def respond_yes(%Auction{id: id}) do
    navigate_to("/auctions/#{id}/rsvp?response=yes")
  end

  def respond_no(%Auction{id: id}) do
    navigate_to("/auctions/#{id}/rsvp?response=no")
  end

  def respond_maybe(%Auction{id: id}) do
    navigate_to("/auctions/#{id}/rsvp?response=maybe")
  end

  def current_response_as_supplier(%Auction{id: auction_id}) do
    find_element(:css, ".qa-auction-#{auction_id}-rsvp-response .selected")
    |> inner_text()
  end

  def supplier_response(supplier_company_id, %Auction{id: auction_id}) do
    find_element(:css, ".qa-auction-#{auction_id}-rsvp-response-#{supplier_company_id}")
    |> inner_text
  end
end
