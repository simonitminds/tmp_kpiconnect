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
    |> Oceanconnect.Guardian.Plug.sign_out()
    |> configure_session(drop: true)
  end

  def current_token(conn) do
    Oceanconnect.Guardian.Plug.current_token(conn)
  end

  def expiration(conn) do
    case Oceanconnect.Guardian.Plug.current_claims(conn) do
      nil -> nil
      claims -> Map.get(claims, "exp")
    end
  end

  def api_login(conn, user) do
    new_conn = Oceanconnect.Guardian.Plug.sign_in(conn, user)
    token = Oceanconnect.Guardian.Plug.current_token(new_conn)
    claims = Oceanconnect.Guardian.Plug.current_claims(new_conn)
    exp = Map.get(claims, "exp")

    new_conn
    |> put_resp_header("authorization", "Bearer #{token}")
    |> put_resp_header("x-expires", "#{exp}")
  end

  def api_logout(conn) do
    token = Oceanconnect.Guardian.Plug.current_token(conn)
    {:ok, _old_claims} = Oceanconnect.Guardian.revoke(token)
    conn
  end
end
