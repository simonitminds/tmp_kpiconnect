defmodule Oceanconnect.NewSessionPage do
  alias Wallaby.{Browser, Query}

  @page_path "/sessions/new"

  use Oceanconnect.Page


  def visit(session) do
    Browser.visit(session, @page_path)
  end

  def enter_credentials(session, email, password) do
    Browser.fill_in(session, Query.css(".qa-session-email"), with: email)
    Browser.fill_in(session, Query.css(".qa-session-password"), with: password)
  end

  def submit(session) do
    Browser.click(session, Query.css(".qa-session-submit"))
  end

  def has_content?(session, title) do
    String.contains?(Browser.page_source(session), title)
  end
end
