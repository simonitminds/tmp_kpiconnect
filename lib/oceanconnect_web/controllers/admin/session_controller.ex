defmodule OceanconnectWeb.Admin.SessionController do
  use OceanconnectWeb, :controller
  import Plug.Conn
  alias Oceanconnect.Accounts.{User}
  alias OceanconnectWeb.Plugs.Auth

  def impersonate(conn, %{"user_id" => user_id}) do
    admin_user = Auth.current_user(conn)
    case Auth.impersonate_user(conn, admin_user, user_id) do
      {:ok, {authed_conn, %User{}}} ->
        authed_conn
        |> redirect(to: auction_path(authed_conn, :index))
      {:error, _reason} ->
        conn
        |> put_status(401)
        |> redirect(to: auction_path(conn, :index))
    end
  end
end
