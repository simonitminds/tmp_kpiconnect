defmodule OceanconnectWeb.TwoFactorAuthController do
  use OceanconnectWeb, :controller
  import Plug.Conn

  alias Oceanconnect.Accounts
  alias OceanconnectWeb.Plugs.Auth

  def new(conn, %{"user_id" => user_id, "token" => token}) do
    render(conn, "two_factor_auth.html", user_id: user_id, token: token, action: two_factor_auth_path(conn, :create))
  end

  def create(conn, %{"one_time_pass" => one_time_pass, "user_id" => user_id, "token" => token}) do
    user = Accounts.get_user!(user_id)
    IO.inspect(one_time_pass, label: "CODE")
    IO.inspect(token, label: "TOKEN")
    case :pot.valid_hotp(one_time_pass, token, [{:last, 0}]) do
      1 ->
        updated_conn =
          conn
          |> Auth.build_session(user)

        updated_conn
        |> redirect(to: auction_path(updated_conn, :index))

      false ->
        conn
        |> put_flash(:error, "Two factor authentification code was invalid")
        |> put_status(401)
        |> render("two_factor_auth.html", user_id: user.id, token: token, action: two_factor_auth_path(conn, :create))
    end
  end
end
