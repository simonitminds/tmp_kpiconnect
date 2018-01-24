defmodule OceanconnectWeb.SessionView do
  use OceanconnectWeb, :view

  def current_user(%Plug.Conn{assigns: %{current_user: user = %Oceanconnect.Accounts.User{}}}) do
    user.email
  end
  def current_user(_conn), do: ""

  def log_in_logout_link(conn) do
    if current_user(conn) != "" do
      link("Log Out", to: session_path(conn, :delete), method: :delete, class: "navbar-item")
    end
  end
end
