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
        |> Enum.reduce(%{}, fn user, acc ->
          company_name = user.company.name
          user_value = [value: user.id, key: "#{user.first_name} #{user.last_name}"]
          user_list = Map.get(acc, user.company.name, [])

          Map.put(acc, company_name, [user_value | user_list])
        end)

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
      user -> Accounts.get_user_name!(user)
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
      nil ->
        ""

      user ->
        user.company.name
    end
  end

  def log_in_logout_link(conn) do
    if current_user(conn) != "" do
      link("Log Out",
        to: session_path(conn, :delete),
        method: :delete,
        class: "navbar-item qa-logout"
      )
    end
  end

  defp admin_present?(conn) do
    if admin = Auth.current_admin(conn) do
      admin.is_admin
    else
      false
    end
  end
end
