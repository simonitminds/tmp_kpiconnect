defmodule OceanconnectWeb.ForgotPasswordControllerTest do
  use OceanconnectWeb.ConnCase

  alias Oceanconnect.Guardian

  setup do
    user = insert(:user, %{email: "FOO@EXAMPLE.COM", password: "password"})

    {:ok, token, _claims} =
      Guardian.encode_and_sign(user, %{user_id: user.id, email: true})

    {:ok, %{user: user, conn: build_conn(), token: token}}
  end

  test "visiting the forgot password page", %{conn: conn} do
    response = get(conn, "/forgot_password")

    assert html_response(response, 200) =~ "/forgot_password"
  end

  test "submitting forgotten password with a valid email address", %{conn: conn, user: user} do
    response = post(conn, "/forgot_password", %{email: user.email})
    assert html_response(response, 302) =~ "/sessions/new"
  end

  test "submitting forgotten password with an invalid email address", %{conn: conn} do
    response = post(conn, "/forgot_password", %{email: "invalid-email@example.com"})
    assert html_response(response, 302) =~ "/sessions/new"
  end

  test "visiting the reset password page", %{conn: conn, token: token} do
    response = get(conn, "/reset_password", %{token: token})
    assert html_response(response, 200) =~ "/reset_password"
  end

  test "submitting a new password with valid credentials", %{conn: conn, token: token} do
    response = post(conn, "/reset_password", %{password: "password", password_confirmation: "password", token: token})
    assert html_response(response, 302) =~ "/sessions/new"
  end

  test "submitting a new password with invalid credentials", %{conn: conn, token: token} do
    response = post(conn, "/reset_password", %{password: "password", password_confirmation: "notpassword", token: token})
    assert html_response(response, 401) =~ "Passwords do not match"
  end
end
