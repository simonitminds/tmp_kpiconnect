defmodule OceanconnectWeb.UserController do
  use OceanconnectWeb, :controller

  alias Oceanconnect.Accounts

  def edit(conn, %{"id" => id}) do
    current_user = Guardian.Plug.current_resource(conn)
    user = Accounts.get_user!(id)
    user_id = user.id

    case current_user.id do
      ^user_id ->
        changeset = Accounts.change_user(user)
        render(conn, "edit.html", user: user, changeset: changeset)

      _ ->
        conn
        |> put_flash(:warning, "Page not found")
        |> redirect(to: "/auctions")
        |> halt()
    end
  end

  def update(conn, %{"id" => id, "user" => user_params}) do
    user = Accounts.get_user!(id)

    case Accounts.update_user(user, user_params) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "User updated successfully.")
        |> redirect(to: user_path(conn, :edit, user))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", user: user, changeset: changeset)
    end
  end
end
