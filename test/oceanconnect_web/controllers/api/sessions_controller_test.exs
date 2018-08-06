defmodule OceanconnectWeb.Api.AuctionControllerTest do
  use OceanconnectWeb.ConnCase
  alias Oceanconnect.Accounts.{User}
  alias OceanconnectWeb.Plugs.Auth

  setup do
    {:ok, user} = Oceanconnect.Accounts.create_user(%{email: "FOO@EXAMPLE.COM", password: "password"})
    {:ok, other_user} = Oceanconnect.Accounts.create_user(%{email: "BAR@EXAMPLE.COM", password: "password"})
    {:ok, admin} = Oceanconnect.Accounts.create_user(%{email: "ADMIN@EXAMPLE.COM", password: "password", is_admin: true})
    {:ok, other_admin} = Oceanconnect.Accounts.create_user(%{email: "ADMIN_TWO@EXAMPLE.COM", password: "password", is_admin: true})
    %{user: user, admin: admin, other_admin: other_admin, other_user: other_user, conn: build_conn()}
  end

  test "impersonating a user session as an admin", %{admin: admin, user: user, conn: conn} do
    authed_conn = OceanconnectWeb.Plugs.Auth.api_login(conn, admin)
    response = put(authed_conn, "/api/sessions/impersonate/#{user.id}", %{})
    {user_id, admin_id} = {user.id, admin.id}
    assert json_response(response, 200)
    assert %User{id: ^user_id, impersonated_by: ^admin_id} = Auth.current_user(response)
  end

  test "impersonating another admin as an admin", %{admin: admin, other_admin: other_admin, conn: conn}  do
    authed_conn = OceanconnectWeb.Plugs.Auth.api_login(conn, admin)
    response = put(authed_conn, "/api/sessions/impersonate/#{other_admin.id}", %{})
    assert json_response(response, 422)
  end

  test "impersonating a user session as a non-admin", %{other_user: other_user, user: user, conn: conn}  do
    authed_conn = OceanconnectWeb.Plugs.Auth.api_login(conn, user)
    response = put(authed_conn, "/api/sessions/impersonate/#{other_user.id}", %{})
    assert json_response(response, 422)
  end
end
