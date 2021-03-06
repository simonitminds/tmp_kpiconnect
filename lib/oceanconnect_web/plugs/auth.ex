defmodule OceanconnectWeb.Plugs.Auth do
  use OceanconnectWeb, :controller
  import Plug.Conn
  alias Oceanconnect.Accounts
  alias Oceanconnect.Accounts.{User}
  alias Oceanconnect.Guardian

  def build_session(conn, user) do
    user_with_company = Accounts.load_company_on_user(user)

    if user_with_company.is_admin do
      Guardian.Plug.sign_in(conn, user_with_company)
      |> Guardian.Plug.sign_in(user_with_company, token: "access", key: :admin)
    else
      Guardian.Plug.sign_in(conn, user_with_company)
    end
  end

  def current_user(conn) do
    Guardian.Plug.current_resource(conn)
  end

  def current_admin(conn) do
    Guardian.Plug.current_resource(conn, key: :admin)
  end

  def current_user_is_admin?(conn) do
    user = Guardian.Plug.current_resource(conn)
    impersonator = Guardian.Plug.current_resource(conn, key: :admin)

    cond do
      user && user.is_admin -> true
      impersonator && impersonator.is_admin -> true
      true -> false
    end
  end

  def browser_logout(conn) do
    conn
    |> Guardian.Plug.sign_out()
    |> configure_session(drop: true)
  end

  def current_token(conn) do
    Guardian.Plug.current_token(conn)
  end

  def expiration(conn) do
    case Guardian.Plug.current_claims(conn) do
      nil -> nil
      claims -> Map.get(claims, "exp")
    end
  end

  def api_login(conn, user) do
    new_conn = Guardian.Plug.sign_in(conn, user)
    token = Guardian.Plug.current_token(new_conn)
    claims = Guardian.Plug.current_claims(new_conn)
    exp = Map.get(claims, "exp")

    new_conn
    |> put_resp_header("authorization", "Bearer #{token}")
    |> put_resp_header("x-expires", "#{exp}")
  end

  def api_logout(conn) do
    token = Guardian.Plug.current_token(conn)
    {:ok, _old_claims} = Guardian.revoke(token)
    conn
  end

  def impersonate_user(conn, current_user = %User{}, user_id) do
    user_with_company =
      Accounts.get_user!(user_id)
      |> Accounts.load_company_on_user()

    sign_in_impersonator(conn, current_user, user_with_company)
  end

  def sign_in_impersonator(conn, %User{is_admin: true}, %User{is_admin: true}) do
    {:error, {conn, "Could Not Impersonate User"}}
  end

  def sign_in_impersonator(conn, impersonator = %User{is_admin: true}, user = %User{}) do
    impersonated_user = %User{user | impersonated_by: impersonator.id}

    authed_conn =
      conn
      |> Guardian.Plug.sign_out()
      |> Guardian.Plug.sign_in(impersonated_user)
      |> Guardian.Plug.sign_in(impersonator, %{}, token_type: "access", key: :admin)

    previous_claims = Guardian.Plug.current_claims(authed_conn)

    authed_conn =
      Guardian.Plug.sign_in(
        authed_conn,
        impersonated_user,
        Map.put(previous_claims, :impersonated_by, impersonator.id)
      )

    {:ok, {authed_conn, impersonated_user}}
  end

  def sign_in_impersonator(conn, _current_user, _user_id) do
    {:error, {conn, "Could Not Impersonate User"}}
  end

  def stop_impersonating(conn) do
    if admin_user = current_admin(conn) do
      conn
      |> Guardian.Plug.sign_out()
      |> Guardian.Plug.sign_in(admin_user)
    else
      conn
    end
  end

  def generate_one_time_pass(%User{has_2fa: true}) do
    token =
      :crypto.strong_rand_bytes(8)
      |> Base.encode32()

    one_time_pass = :pot.hotp(token, _num_of_trials = 1)

    {token, one_time_pass}
  end

  def assign_otp_data_to_session(conn, token, user_id) do
    plug_session =
      conn.private[:plug_session]
      |> Map.put("user_data", %{"otp_token" => token, "user_id" => user_id})

    conn
    |> put_private(:plug_session, plug_session)
  end

  def fetch_otp_data_from_session(conn) do
    Kernel.get_in(conn.private, [:plug_session, "user_data"])
  end

  def valid_otp?(token, one_time_pass) do
    case token do
      nil ->
        false

      _ ->
        case :pot.valid_hotp(one_time_pass, token, [{:last, 0}]) do
          1 -> true
          _ -> false
        end
    end
  end

  def invalidate_otp(conn, user_id) do
    plug_session =
      conn.private[:plug_session]
      |> Map.put("user_data", %{"otp_token" => nil, "user_id" => user_id})

    conn
    |> put_private(:plug_session, plug_session)
  end
end
