defmodule OceanconnectWeb.RegistrationControllerTest do
  use OceanconnectWeb.ConnCase

  setup do
    user = insert(:user)

    {:ok, %{user: user, conn: build_conn()}}
  end

  test "visiting the registration page", %{conn: conn} do
    response = get(conn, "/registration")
    assert html_response(response, 200) =~ "/registration"
  end

  test "submitting valid data to registration redirects you to /session/new", %{conn: conn, user: user} do
    response = post(conn, "/registration", %{email: user.email})
    assert html_response(response, 302) =~ "/sessions/new"
  end

  test "submitting invalid data to registration puts an error flash", %{conn: conn} do
    response = post(conn, "/registration", %{email: nil})
    assert html_response(response, 401) =~ "Please make sure to include your email address!"
  end
end
