defmodule OceanconnectWeb.SessionController do
  use OceanconnectWeb, :controller
  import Plug.Conn
  alias Oceanconnect.Accounts
  alias OceanconnectWeb.Plugs.Auth

  def new(conn, _) do
    render(conn, "new.html")
  end

  def create(conn, %{"session" => session}) do
    case Accounts.verify_login(session) do
      {:ok, user} ->
        case user.has_2fa do
          true ->
            {token, one_time_pass} = Auth.generate_one_time_pass(user)
            OceanconnectWeb.Mailer.deliver_2fa_email(user, one_time_pass)

            conn
            |> Auth.assign_otp_data_to_session(token, user.id)
            |> put_flash(:info, "A two-factor authentication code has been sent to your email")
            |> put_status(302)
            |> redirect(to: two_factor_auth_path(conn, :new))
          false ->
            updated_conn =
              conn
              |> Auth.build_session(user)

            updated_conn
            |> redirect(to: auction_path(updated_conn, :index))
        end

      {:error, _} ->
        conn
        |> put_flash(:error, "Invalid email/password")
        |> put_status(401)
        |> render("new.html")
    end
  end

  def delete(conn, _) do
    conn
    |> Auth.browser_logout()
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
