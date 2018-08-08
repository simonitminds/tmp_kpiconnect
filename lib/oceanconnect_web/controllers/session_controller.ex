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
        updated_conn = conn
        |> Auth.build_session(user)
        updated_conn
        |> redirect(to: auction_path(updated_conn, :index))

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

  def stop_impersonating(conn, _params) do
    updated_conn = Auth.stop_impersonating(conn)
    updated_conn
    |> redirect(to: auction_path(updated_conn, :index))
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
