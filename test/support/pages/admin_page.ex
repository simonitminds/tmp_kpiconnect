defmodule Oceanconnect.AdminPage do
  use Oceanconnect.Page
  alias Oceanconnect.Accounts.User

  def impersonate_user(%User{id: user_id}) do
    find_element(:css, ".qa-admin-act-as-agent")
    |> click

    find_element(:css, ".qa-admin-impersonate-user option[value='#{user_id}']")
    |> click

    find_element(:css, ".qa-admin-impersonate-user-submit")
    |> click
  end

  def stop_impersonating() do
    find_element(:css, ".qa-admin-act-as-admin")
    |> click
  end

  def logged_in_as?(%User{first_name: first, last_name: last}) do
    find_element(:css, ".navbar-item--user")
    |> inner_text =~ "#{first} #{last}"
  end
end
