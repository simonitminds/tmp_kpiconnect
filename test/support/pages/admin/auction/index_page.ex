defmodule Oceanconnect.Admin.Auction.IndexPage do
  use Oceanconnect.Page
  @page_path "/admin/auctions"

  def visit() do
    navigate_to(@page_path)
  end


  def is_current_path? do
    current_path() == @page_path
  end

  def has_fixture?(auction_id) do
    has_css?(".qa-fixture-for-auction-#{auction_id}")
  end
end
