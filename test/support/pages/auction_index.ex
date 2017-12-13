defmodule Oceanconnect.AuctionIndex do
  # use Oceanconnect.Page
  import Wallaby.Browser, only: [page_title: 1, visit: 2, page_source: 1]

  def visit(session) do
    visit(session, "/auctions")
  end

  def has_content?(session, title) do
    String.contains?(page_source(session), title)
  end
end
