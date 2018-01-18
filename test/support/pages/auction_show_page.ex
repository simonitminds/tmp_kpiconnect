defmodule Oceanconnect.AuctionShowPage do
  @page_path "/auctions/"
  use Oceanconnect.Page

  def visit(id) do
    navigate_to("#{@page_path}#{id}")
  end

  def auction_status() do
    find_element(:class, "qa-auction-status").inner_text()
  end
end
