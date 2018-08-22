defmodule OceanconnectWeb.Api.SessionController do
  use OceanconnectWeb, :controller
  alias Oceanconnect.Accounts.{User}
  alias OceanconnectWeb.Plugs.Auth

  def impersonate(conn, %{"user_id" => user_id}) do
    admin_user = Auth.current_user(conn)

    case Auth.impersonate_user(conn, admin_user, user_id) do
      {:ok, {updated_conn, %User{} = user}} ->
        render(updated_conn, "impersonate.json", data: {user, admin_user})

      {:error, {error_conn, _reason}} ->
        error_conn
        |> put_status(422)
        |> render(OceanconnectWeb.ErrorView, "422.json", data: %{})
    end
  end
end
