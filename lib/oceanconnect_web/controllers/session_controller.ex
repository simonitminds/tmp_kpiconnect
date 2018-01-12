defmodule OceanconnectWeb.SessionController do
  use OceanconnectWeb, :controller
  alias Oceanconnect.Accounts
  alias OceanconnectWeb.Plugs.Auth

  def new(conn, _) do
    render(conn, "new.html")
  end

  def create(conn, %{"session" => session}) do
    case Accounts.verify_login(session) do
      {:ok, user} ->
        conn
        |> Auth.build_session(user)
        |> redirect(to: auction_path(conn, :index))

      {:error, _} ->
        conn
        |> put_flash(:error, "Invalid email/password")
        |> put_status(401)
        |> render("new.html")
    end
  end

  def delete(conn, _) do
    conn
    |> Auth.browser_logout
    |> put_status(302)
    |> redirect(to: session_path(conn, :new))
  end

  def already_authenticated(conn, _) do
    conn
    |> put_status(302)
    |> redirect(to: auction_path(conn, :index))
  end

  def unauthenticated(conn) do
    conn
    |> put_flash(:error, "Authentication Required")
    |> put_status(302)
    |> redirect(to: session_path(conn, :new))
  end
end
