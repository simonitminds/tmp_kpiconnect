defmodule OceanconnectWeb.TwoFactorAuthControllerTest do
  use OceanconnectWeb.ConnCase

  setup do
    user = insert(:user, %{password: "password", has_2fa: true})
    token =
      :crypto.strong_rand_bytes(8)
      |> Base.encode32()

    one_time_pass = :pot.hotp(token, _num_of_trials = 1)
    {:ok, %{conn: build_conn(), user: user, token: token, one_time_pass: one_time_pass}}
  end

  test "visiting the two factor auth page", %{conn: conn, user: user, token: token} do
    response = get(conn, "/sessions/new/two_factor_auth", %{user_id: user.id, token: token})
    assert html_response(response, 200) =~ "/sessions/new/two_factor_auth"
  end

  test "submitting a new password with a valid one time password", %{conn: conn, user: user, token: token, one_time_pass: one_time_pass} do
    response = post(conn, "/sessions/new/two_factor_auth", %{one_time_pass: one_time_pass, user_id: user.id, token: token})
    assert html_response(response, 302) =~ "/auctions"
  end
end
