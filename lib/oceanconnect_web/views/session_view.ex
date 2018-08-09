defmodule OceanconnectWeb.SessionView do
  use OceanconnectWeb, :view
  alias OceanconnectWeb.Plugs.Auth
  alias Oceanconnect.Accounts
  alias Oceanconnect.Accounts.User

  def current_user_is_admin?(conn) do
    case Auth.current_user(conn) do
      nil -> false
      user -> user.is_admin || admin_present?(conn)
    end
  end

  def impersonable_users(conn) do
    case current_user_is_admin?(conn) do
      true ->
        conn
        |> Auth.current_user()
        |> Accounts.impersonable_users_for()
        |> Enum.map(&([value: &1.id, key: "#{&1.first_name} #{&1.last_name} (#{&1.company.name})"]))
      false ->
        []
    end
  end

  def is_impersonating?(conn) do
    current_user = Auth.current_user(conn)
    current_admin = Auth.current_admin(conn)
    case current_user do
      %User{is_admin: true} -> false
      %User{is_admin: false} -> !!current_admin
      _ -> false
    end
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

  defp admin_present?(conn) do
    admin_present? = if admin = Auth.current_admin(conn) do
      admin.is_admin
    else
      false
    end
  end
end
