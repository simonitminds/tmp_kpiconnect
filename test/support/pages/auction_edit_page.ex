defmodule Oceanconnect.AuctionEditPage do
  use Oceanconnect.Page


  def visit(id) do
    navigate_to("/auctions/#{id}/edit")
  end

  def has_fields?(fields) do
    Enum.all?(fields, fn(field) ->
      find_element(:class, "qa-auction-#{field}")
    end)
  end
end
