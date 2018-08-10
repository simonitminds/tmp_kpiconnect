defmodule OceanconnectWeb.Plugs.AuthTest do
  use OceanconnectWeb.ConnCase
  alias Oceanconnect.Accounts.{User}
  alias OceanconnectWeb.Plugs.Auth

  setup do
    user = insert(:user, %{email: "FOO@EXAMPLE.COM", password: "password"})
    other_user = insert(:user, %{email: "BAR@EXAMPLE.COM", password: "password"})
    admin = insert(:user, %{email: "ADMIN@EXAMPLE.COM", password: "password", is_admin: true})
    other_admin =  insert(:user, %{email: "ADMIN_TWO@EXAMPLE.COM", password: "password", is_admin: true})
    %{user: user, admin: admin, other_admin: other_admin, other_user: other_user, conn: build_conn()}
  end

  test "impersonating a user sets the impersonated_by on session", %{conn: conn, user: user, admin: admin} do
    admin_id = admin.id
    {:ok, {conn, _user}} = OceanconnectWeb.Plugs.Auth.api_login(conn, admin)
    |> Auth.impersonate_user(admin, user.id)
    current_user = conn
    |> Auth.current_user

    assert %User{impersonated_by: ^admin_id} = current_user
  end

  test "impersonating an admin user errors", %{conn: conn, other_admin: other_admin, admin: admin} do
    session = OceanconnectWeb.Plugs.Auth.api_login(conn, admin)
    |> Auth.impersonate_user(admin, other_admin.id)

    assert {:error, {session_conn, _reason}}  = session

    current_user = session_conn
    |> Auth.current_user

    assert %User{impersonated_by: nil} = current_user
  end

  test "impersonating a user as a non-admin errors", %{conn: conn, user: user, other_user: other_user} do
    session = OceanconnectWeb.Plugs.Auth.api_login(conn, user)
    |> Auth.impersonate_user(user, other_user.id)

    assert {:error, {session_conn, _reason}}  = session

    current_user = session_conn
    |> Auth.current_user

    assert %User{impersonated_by: nil} = current_user
  end
end
