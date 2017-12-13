defmodule Oceanconnect.IndexPage do
  # use Oceanconnect.Page
  import Wallaby.Browser, only: [page_title: 1, visit: 2]

  def visit(session) do
    visit(session, "/")
  end

  def has_title?(session, title) do
    page_title(session) == title
  end
end
