defmodule OceanconnectWeb.SessionView do
  use OceanconnectWeb, :view
  alias OceanconnectWeb.Plugs.Auth
  alias Oceanconnect.Accounts

  def current_user_is_admin?(conn) do
    case Auth.current_user(conn) do
      nil -> false
      user -> user.is_admin
    end
  end

  def impersonable_users(conn) do
    case current_user_is_admin?(conn) do
      true ->
        conn
        |> Auth.current_user()
        |> Accounts.impersonable_users_for()
        |> Enum.map(&(%{id: &1.id,
                       first_name: &1.first_name,
                       last_name: &1.last_name,
                       company_name: &1.company.name }))
      false ->
        []
    end
    |> Poison.encode!
    |> Phoenix.HTML.raw
  end

  def current_user(conn) do
    case Auth.current_user(conn) do
      nil -> ""
      user -> "#{user.first_name} #{user.last_name}"
    end
  end

  def current_user_company_id(conn) do
    case Auth.current_user(conn) do
      nil -> ""
      user -> user.company.id
    end
  end

  def current_company(conn) do
    case Auth.current_user(conn) do
      nil -> ""
      user -> user.company.name
    end
  end

  def log_in_logout_link(conn) do
    if current_user(conn) != "" do
      link("Log Out", to: session_path(conn, :delete), method: :delete, class: "navbar-item")
    end
  end
end
