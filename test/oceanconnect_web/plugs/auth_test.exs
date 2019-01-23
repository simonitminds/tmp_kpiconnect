defmodule OceanconnectWeb.Plugs.AuthTest do
  use OceanconnectWeb.ConnCase
  use Bamboo.Test

  alias Oceanconnect.Accounts.{User}
  alias OceanconnectWeb.Plugs.Auth

  setup do
    user = insert(:user, %{email: "FOO@EXAMPLE.COM", password: "password"})
    user_with_2fa = insert(:user, %{has_2fa: true})
    other_user = insert(:user, %{email: "BAR@EXAMPLE.COM", password: "password"})
    admin = insert(:user, %{email: "ADMIN@EXAMPLE.COM", password: "password", is_admin: true})

    other_admin =
      insert(:user, %{email: "ADMIN_TWO@EXAMPLE.COM", password: "password", is_admin: true})

    %{
      user: user,
      user_with_2fa: user_with_2fa,
      admin: admin,
      other_admin: other_admin,
      other_user: other_user,
      conn: build_conn()
    }
  end

  test "impersonating a user sets the impersonated_by on session", %{
    conn: conn,
    user: user,
    admin: admin
  } do
    admin_id = admin.id

    {:ok, {conn, _user}} =
      OceanconnectWeb.Plugs.Auth.api_login(conn, admin)
      |> Auth.impersonate_user(admin, user.id)

    current_user =
      conn
      |> Auth.current_user()

    assert %User{impersonated_by: ^admin_id} = current_user
  end

  test "impersonating an admin user errors", %{conn: conn, other_admin: other_admin, admin: admin} do
    session =
      OceanconnectWeb.Plugs.Auth.api_login(conn, admin)
      |> Auth.impersonate_user(admin, other_admin.id)

    assert {:error, {session_conn, _reason}} = session

    current_user =
      session_conn
      |> Auth.current_user()

    assert %User{impersonated_by: nil} = current_user
  end

  test "impersonating a user as a non-admin errors", %{
    conn: conn,
    user: user,
    other_user: other_user
  } do
    session =
      OceanconnectWeb.Plugs.Auth.api_login(conn, user)
      |> Auth.impersonate_user(user, other_user.id)

    assert {:error, {session_conn, _reason}} = session

    current_user =
      session_conn
      |> Auth.current_user()

    assert %User{impersonated_by: nil} = current_user
  end

  describe "one time password" do
    test "generating and validating a one time password", %{user_with_2fa: user_with_2fa} do
      {token, one_time_pass} = Auth.generate_one_time_pass(user_with_2fa)
      assert Auth.valid_otp?(token, one_time_pass)
    end

    test "assigning and fetching otp data to and from session's private storage", %{user_with_2fa: user_with_2fa} do
      {token, _one_time_pass} = Auth.generate_one_time_pass(user_with_2fa)
      user_id = user_with_2fa.id

      conn =
        build_conn()
        |> put_private(:plug_session, %{})

      updated_conn =
        conn
        |> Auth.assign_otp_data_to_session(token, user_id)

      assert %{"otp_token" => token, "user_id" => user_id} = Auth.fetch_otp_data_from_session(updated_conn)
    end

    test "invalidating one time password", %{user_with_2fa: user_with_2fa} do
      {token, one_time_pass} = Auth.generate_one_time_pass(user_with_2fa)
      user_id = user_with_2fa.id

      conn =
        build_conn()
        |> put_private(:plug_session, %{})

      updated_conn =
        conn
        |> Auth.assign_otp_data_to_session(token, user_id)

      assert %{"otp_token" => token, "user_id" => user_id} = Auth.fetch_otp_data_from_session(updated_conn)

      invalid_conn =
        updated_conn
        |> Auth.invalidate_otp(user_id)

      %{"otp_token" => invalid_token, "user_id" => user_id} = Auth.fetch_otp_data_from_session(invalid_conn)
      refute Auth.valid_otp?(invalid_token, one_time_pass)
    end
  end
end
