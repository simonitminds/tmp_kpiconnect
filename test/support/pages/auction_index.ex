defmodule Oceanconnect.AuctionIndex do
  @page_path "/auctions"
  use Oceanconnect.Page

  def visit do
    navigate_to(@page_path)
  end
end
