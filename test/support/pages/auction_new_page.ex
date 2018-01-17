defmodule Oceanconnect.AuctionNewPage do
  @page_path "/auctions/new"
  use Oceanconnect.Page

  def visit do
    navigate_to(@page_path)
  end

  def has_fields?(fields) do
    Enum.all?(fields, fn(field) ->
      find_element(:class, "qa-auction-#{field}")
    end)
  end

  def vessel_list() do
    find_all_elements(:css, ".qa-auction-vessel option")
    |> Enum.map(fn(elem) -> inner_text(elem) end)
  end
end
