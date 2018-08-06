defmodule Oceanconnectweb.SessionControllerTest do
  use OceanconnectWeb.ConnCase
  alias Oceanconnect.Accounts.User

  setup do
    {:ok, user} = Oceanconnect.Accounts.create_user(%{email: "FOO@EXAMPLE.COM", password: "password"})
    {:ok, admin} = Oceanconnect.Accounts.create_user(%{email: "ADMIN@EXAMPLE.COM", password: "password", is_admin: true})
    %{user: user, admin: admin, conn: build_conn()}
  end

  test "confirm login page renders", %{conn: conn} do
    response = get(conn, "/sessions/new")
    assert html_response(response, 200) =~ "Password"
  end

  test "logging in", %{conn: conn} do
    response = post(conn, "/sessions", %{"session": %{email: "FOO@EXAMPLE.COM", password: "password"}})
    assert redirected_to(response, 302) =~ "/auctions"
  end

  test "logging in with mixed case email", %{conn: conn} do
    response = post(conn, "/sessions", %{"session": %{email: "Foo@example.com", password: "password"}})
    assert redirected_to(response, 302) =~ "/auctions"
  end

  test "invalid password", %{conn: conn} do
    response = post(conn, "/sessions", %{"session": %{email: "foo@example.com", password: "wrongpassword"}})
    assert html_response(response, 401) =~ "Invalid email/password"
  end

  test "invalid email", %{conn: conn} do
    response = post(conn, "/sessions", %{"session": %{email: "test@example.com", password: "password"}})
    assert html_response(response, 401) =~ "Invalid email/password"
  end

  test "blank credentials", %{conn: conn} do
    response = post(conn, "/sessions", %{"session": %{email: "", password: ""}})
    assert html_response(response, 401) =~ "Invalid email/password"
  end

  test "logging out", %{conn: conn} do
    response = conn
    |> post("/sessions", %{"session": %{email: "foo@example.com", password: "password"}})
    |> delete("/sessions/logout")
    assert redirected_to(response, 302) =~ "/sessions/new"
  end

  test "logging out invalidates session", %{conn: conn} do
    response = conn
    |> post("/sessions", %{"session": %{email: "foo@example.com", password: "password"}})
    |> delete("/sessions/logout")
    |> get("/auctions")

    assert redirected_to(response, 302) =~ "/sessions/new"
    assert response.private.phoenix_flash["error"] == "Authentication Required"
  end

  test "impersonating a user session as an admin", %{admin: admin, user: user, conn: conn} do
    updated_conn = post(conn, "/sessions", %{"session": %{email: "ADMIN@EXAMPLE.COM", password: "password"}})
    assert redirected_to(updated_conn, 302) =~ "/auctions"
    response = put(conn, "/sessions/impersonate/#{user.id}", %{})
    assert html_response(response, 200)
    assert %User{id: user.id, impersonated_by: admin.id} == Auth.current_user(response)
  end

  test "impersonating another admin as an admin" do

  end

  test "impersonating a user session as a non-admin" do

  end
  # test "already logged in", %{conn: conn} do
  #   response = post(conn, "/sessions", %{"session": %{email: "foo@example.com", password: "password"}})

  #   new_response = get(response, "/sessions")

  #   assert redirected_to(new_response, 302) =~ "/user/dashboard"
  # end

  # test "invalid credentials" do
  #   response = get(build_conn(), "/user/dashboard")
  #   assert redirected_to(response, 302) =~ "/sessions"
  #   assert response.private.phoenix_flash["error"] == "Authentication Required"
  # end
end
