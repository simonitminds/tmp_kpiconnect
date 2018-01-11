defmodule Oceanconnectweb.SessionControllerTest do
  use OceanconnectWeb.ConnCase

  setup do
    {:ok, user} = Oceanconnect.Accounts.create_user(%{email: "foo@example.com", password: "password"})
    %{user: user, conn: build_conn()}
  end

  test "confirm login page renders", %{conn: conn} do
    response = get(conn, "/sessions/new")
    assert html_response(response, 200) =~ "Password"
  end

  test "logging in", %{conn: conn} do
    response = post(conn, "/sessions", %{"session": %{email: "foo@example.com", password: "password"}})
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

  # test "logging out", %{conn: conn} do
  #   response = conn
  #   |> post("/sessions", %{"session": %{email: "foo@example.com", password: "password"}})
  #   |> delete("/user/logout")
  #   assert redirected_to(response, 302) =~ "/sessions"
  # end
  #
  # test "logging out invalidates session", %{conn: conn} do
  #   response = conn
  #   |> post("/sessions", %{"session": %{email: "foo@example.com", password: "password"}})
  #   |> delete("/user/logout")
  #   |> get("/user/dashboard")
  #
  #   assert redirected_to(response, 302) =~ "/sessions"
  #   assert response.private.phoenix_flash["error"] == "Authentication Required"
  # end

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
