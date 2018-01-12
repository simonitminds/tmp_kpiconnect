defmodule OceanconnectWeb.Plugs.Auth do
  import Plug.Conn

  def init(default), do: default

  def call(conn, _default) do
    ensure_authenticated(conn)
  end

  def build_session(conn, user) do
    conn
    |> put_session(:user, user)
    |> assign(:current_user, user)
    |> configure_session(renew: true)
  end

  def browser_logout(conn) do
    conn
    |> configure_session(drop: true)
  end

  def ensure_authenticated(conn) do
    case get_session(conn, :user) do
      nil ->
        conn
        |> halt
        |> OceanconnectWeb.SessionController.unauthenticated
      user -> assign(conn, :current_user, user)
    end
  end
end
