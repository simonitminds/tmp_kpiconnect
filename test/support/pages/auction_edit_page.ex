defmodule Oceanconnect.AuctionEditPage do
  # use Oceanconnect.Page
  import Wallaby.Browser, only: [page_source: 1]
  alias Wallaby.{Browser}

  def visit(session, id) do
    Browser.visit(session, "/auctions/#{id}/edit")
  end

  def has_content?(session, title) do
    String.contains?(page_source(session), title)
  end

  def has_fields?(session, fields) do
    Enum.all?(fields, fn(field) ->
      Browser.has_css?(session, ".qa-auction-#{field}")
    end)
  end
end
