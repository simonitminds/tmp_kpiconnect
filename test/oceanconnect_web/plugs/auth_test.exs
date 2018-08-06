defmodule OceanconnectWeb.Plugs.AuthTest do
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

  test "impersonating a user sets the impersonated_by on session", %{conn: conn, user: user, admin: admin} do
    admin_id = admin.id
    {:ok, {conn, _user}} = OceanconnectWeb.Plugs.Auth.api_login(build_conn(), admin)
    |> Auth.impersonate_user(admin, user.id)
    current_user = conn
    |> Auth.current_user

    assert %User{impersonated_by: ^admin_id} = current_user
  end
end
