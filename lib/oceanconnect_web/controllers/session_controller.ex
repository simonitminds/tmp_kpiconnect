defmodule OceanconnectWeb.SessionController do
  use OceanconnectWeb, :controller
  import Plug.Conn
  alias Oceanconnect.Accounts
  alias Oceanconnect.Accounts.{User}
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

  def impersonate(conn, %{"user_id" => user_id}) do
    admin_user = Auth.current_user(conn)
    case Auth.impersonate_user(conn, admin_user, user_id) do
      {:ok, {authed_conn, %User{} = user}} ->
        authed_conn
        |> redirect(to: auction_path(authed_conn, :index))
      {:error, _reason} ->
        conn
        |> put_status(401)
        |> redirect(to: auction_path(conn, :index))
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

  def auth_error(conn = %Plug.Conn{request_path: path}, {_type, _reason}, _opts) do
    case String.match?(path, ~r/\/api\//) do
      true ->
        conn
        |> put_status(401)
        |> render(OceanconnectWeb.ErrorView, "401.json", data: %{})
      false ->
        conn
        |> put_flash(:error, "Authentication Required")
        |> put_status(302)
        |> redirect(to: session_path(conn, :new))
    end
  end
end
