defmodule OceanconnectWeb.SessionView do
  use OceanconnectWeb, :view
  alias OceanconnectWeb.Plugs.Auth

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
