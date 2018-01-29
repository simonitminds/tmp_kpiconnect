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
    |> put_user_token
  end

  def current_user(conn) do
    conn.assigns[:current_user]
  end

  def browser_logout(conn) do
    conn
    |> configure_session(drop: true)
  end

  def generate_user_token(conn, %Oceanconnect.Accounts.User{id: user_id}) do
    Phoenix.Token.sign(conn, "user socket", user_id)
  end

  defp ensure_authenticated(conn) do
    case get_session(conn, :user) do
      nil ->
        conn
        |> halt
        |> OceanconnectWeb.SessionController.unauthenticated
      user ->
        assign(conn, :current_user, user)
        |> put_user_token
    end
  end

  defp put_user_token(conn) do
    if current_user = conn.assigns[:current_user] do
      token = generate_user_token(conn, current_user)
      assign(conn, :user_token, token)
    else
      conn
    end
  end

end
