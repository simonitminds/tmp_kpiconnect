defmodule Oceanconnect.Admin.Fixture.IndexPage do
  use Oceanconnect.Page
  @page_path "/admin/auctions"

  def visit(auction_id) do
    navigate_to("#{@page_path}/#{auction_id}/fixtures")
  end

  def is_current_path?(auction_id) do
    current_path() == "#{@page_path}/#{auction_id}/fixtures"
  end

  def has_fixture?(%{id: auction_fixture_id}) do
    has_css?(".qa-auction-fixture-#{auction_fixture_id}")
  end
end
