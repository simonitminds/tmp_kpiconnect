defmodule Oceanconnect.AuctionIndex do
  import Wallaby.Browser, only: [visit: 2, page_source: 1]
  @page_path "/auctions"
  use Oceanconnect.Page

  def visit(session) do
    visit(session, @page_path)
  end

  def has_content?(session, title) do
    String.contains?(page_source(session), title)
  end
end
