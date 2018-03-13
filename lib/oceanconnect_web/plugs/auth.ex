defmodule OceanconnectWeb.Plugs.Auth do
  use OceanconnectWeb, :controller
  import Plug.Conn

  def build_session(conn, user) do
    user_with_company = Oceanconnect.Accounts.load_company_on_user(user)
    Oceanconnect.Guardian.Plug.sign_in(conn, user_with_company)
  end

  def current_user(conn) do
    Oceanconnect.Guardian.Plug.current_resource(conn)
  end

  def browser_logout(conn) do
    conn
    |> Oceanconnect.Guardian.Plug.sign_out
    |> configure_session(drop: true)
  end

  def current_token(conn) do
    Oceanconnect.Guardian.Plug.current_token(conn)
  end
end
