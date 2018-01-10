defmodule OceanconnectWeb.Admin.SessionController do
  use OceanconnectWeb, :controller
  alias OceanconnectWeb.Accounts

  # plug EnsureNotAuthenticated, [handler: __MODULE__] when action in [:new, :create]

  def new(conn, _) do
    render(conn, "login.html")
  end

  def create(conn, %{"session" => session}) do
    case Accounts.verify_login(session) do
      {:ok, user} ->
        conn
        |> Auth.build_session(user)
        |> redirect(to: auctions_path(conn, :index))

      {:error, _} ->
        conn
        |> put_flash(:error, "Invalid email/password")
        |> put_status(401)
        |> render("login.html")
    end
  end
end
