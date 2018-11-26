defmodule Oceanconnect.NewSessionPage do
  @page_path "/sessions/new"

  use Oceanconnect.Page

  def visit do
    navigate_to(@page_path)
  end

  def enter_credentials(email, password) do
    fill_field({:class, "qa-session-email"}, email)
    fill_field({:class, "qa-session-password"}, password)
  end

  def submit do
    click({:class, "qa-session-submit"})
  end

  def logout do
    find_element(:css, ".qa-app-navbar")
    |> click()

    find_element(:css, ".qa-logout")
    |> click()
  end
end
