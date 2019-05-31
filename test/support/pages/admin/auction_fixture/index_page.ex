defmodule Oceanconnect.Admin.Fixture.IndexPage do
  use Oceanconnect.Page
  @page_path "/admin/auctions/fixtures"

  def visit do
    navigate_to("#{@page_path}")
  end

  def is_current_path? do
    current_path() == "#{@page_path}"
  end

  def has_fixture?(%{id: auction_fixture_id}) do
    has_css?(".qa-auction-fixture-#{auction_fixture_id}")
  end
end
