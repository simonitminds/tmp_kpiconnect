defmodule Oceanconnect.IndexPage do
  use Oceanconnect.Page

  def visit do
    navigate_to("/")
  end

  def has_title?(title) do
    page_title() == title
  end
end
