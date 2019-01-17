defmodule OceanconnectWeb.TwoFactorAuthControllerTest do
  use OceanconnectWeb.ConnCase

  alias OceanconnectWeb.Plugs.Auth

  setup do
    user = insert(:user, %{password: "password", has_2fa: true})
    {token, one_time_pass} = Auth.generate_one_time_pass(user)

    conn =
      build_conn()

    plug_session =
      Map.put(%{}, "user_data", %{"otp_token" => token, "user_id" => user.id})

    conn =
      conn
      |> put_private(:plug_session, plug_session)

    {:ok, %{conn: conn, one_time_pass: one_time_pass, user: user}}
  end

  test "visiting the two factor auth page", %{conn: conn} do
    response = get(conn, "/sessions/new/two_factor_auth")
    assert html_response(response, 200) =~ "/sessions/new/two_factor_auth"
  end

  test "visiting the two factor auth page with no token", %{conn: conn, user: user} do
    invalid_conn =
      conn
      |> Auth.invalidate_otp(user.id)

    response = get(invalid_conn, "/sessions/new/two_factor_auth")
    assert html_response(response, 302) =~ "/sessions/new"
  end

  test "submitting a session with a valid one time password", %{conn: conn, one_time_pass: one_time_pass} do
    response = post(conn, "/sessions/new/two_factor_auth", %{one_time_pass: one_time_pass})
    assert html_response(response, 302) =~ "/auctions"
  end

  test "submitting a session with an invalid one time password", %{conn: conn} do
    response = post(conn, "/sessions/new/two_factor_auth", %{one_time_pass: "not the one time password"})
    assert html_response(response, 401) =~ "The authentication code entered was invalid"
  end

  test "resending the 2fa email", %{conn: conn} do
    response = post(conn, "/sessions/new/two_factor_auth/resend_email")
    assert html_response(response, 200) =~ "A new two-factor authentication code has been sent to your email"
  end
end
