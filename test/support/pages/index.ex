defmodule Oceanconnect.IndexPage do
  @page_path "/"
  use Oceanconnect.Page

  def visit do
    navigate_to("/")
  end

  def has_title?(title) do
    page_title() == title
  end
end
