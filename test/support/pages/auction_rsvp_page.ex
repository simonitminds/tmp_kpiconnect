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

  def respond_to_invitation(%Auction{id: auction_id}, response) do
    find_element(:css, ".qa-auction-#{auction_id}-rsvp-response-#{response}")
    |> click()
  end

  def current_response_as_supplier(%Auction{id: auction_id}) do
    find_element(:css, ".qa-auction-#{auction_id}-rsvp-response[data-selected=true]")
    |> inner_text()
    |> String.trim()
  end

  def supplier_response(supplier_company_id, %Auction{id: auction_id}) do
    find_element(:css, ".qa-auction-#{auction_id}-rsvp-response-#{supplier_company_id}")
    |> inner_text
  end

  def supplier_response_as_buyer(supplier_company_id) do
    response =
      find_element(:css, ".qa-auction-suppliers")
      |> find_within_element(:css, ".qa-auction-rsvp-response-#{supplier_company_id}")
      |> inner_html

    cond do
      response =~ "fa-adjust" -> "No Response"
      response =~ "fa-check-circle" -> "Accept"
      response =~ "fa-times-circle" -> "Decline"
      response =~ "fa-minus-circle" -> "Maybe"
    end
  end
end
