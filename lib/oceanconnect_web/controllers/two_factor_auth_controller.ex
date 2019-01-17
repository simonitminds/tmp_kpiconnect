defmodule OceanconnectWeb.TwoFactorAuthController do
  use OceanconnectWeb, :controller
  import Plug.Conn

  alias Oceanconnect.Accounts
  alias OceanconnectWeb.Plugs.Auth

  def new(conn, _) do
    token =
      Kernel.get_in(conn.private[:plug_session], ["user_data", "otp_token"])

    case token do
      nil ->
        conn
        |> put_flash(:error, "Page not found")
        |> put_status(302)
        |> redirect(to: session_path(conn, :new))
      _ ->
        render(conn, "two_factor_auth.html", action: two_factor_auth_path(conn, :create))
    end
  end

  def create(conn, %{"one_time_pass" => one_time_pass}) do
    %{"otp_token" => token, "user_id" => user_id} = Auth.fetch_otp_data_from_session(conn)
    user = Accounts.get_user!(user_id)

    case Auth.valid_otp?(token, one_time_pass) do
      true ->
        updated_conn =
          conn
          |> Auth.invalidate_otp(user_id)
          |> Auth.build_session(user)

        updated_conn
        |> redirect(to: auction_path(updated_conn, :index))

      false ->
        conn
        |> put_flash(:error, "The authentication code entered was invalid")
        |> put_status(401)
        |> render("two_factor_auth.html", action: two_factor_auth_path(conn, :create))
    end
  end

  def resend_email(conn, _) do
    user_id =
      Kernel.get_in(conn.private[:plug_session], ["user_data", "user_id"])

    user = Accounts.get_user!(user_id)
    {token, one_time_pass} = Auth.generate_one_time_pass(user)
    OceanconnectWeb.Mailer.deliver_2fa_email(user, one_time_pass)

    conn
    |> Auth.assign_otp_data_to_session(token, user_id)
    |> put_flash(:info, "A new two-factor authentication code has been sent to your email")
    |> put_status(200)
    |> render("two_factor_auth.html", action: two_factor_auth_path(conn, :create))
  end
end
