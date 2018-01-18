defmodule Oceanconnect.Accounts.Auth do
  import Plug.Conn

  def build_session(conn, user) do
    conn
    |> put_session(:user_id, user.id)
    |> assign(:current_user, user)
    |> configure_session(renew: true)
  end

  def current_user(conn) do
    conn.assigns[:current_user]
  end
end
