defmodule Oceanconnect.AuctionIndexPage do
  @page_path "/auctions"
  use Oceanconnect.Page

  def visit do
    navigate_to(@page_path)
  end

  def start_auction(auction) do
    find_element(:class, "qa-auction-#{auction.id}")
    |> find_within_element(:class, "qa-auction-start")
    |> click
  end
end
