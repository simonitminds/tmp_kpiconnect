defmodule OceanconnectWeb.Admin.UserController do
  use OceanconnectWeb, :controller

  alias Oceanconnect.Accounts
  alias Oceanconnect.Accounts.User

  def index(conn, params) do
    page = Accounts.list_users(params)

    render(
      conn,
      "index.html",
      users: page.entries,
      page_number: page.page_number,
      page_size: page.page_size,
      total_pages: page.total_pages,
      total_entries: page.total_entries
    )
  end

  def new(conn, _params) do
    changeset = Accounts.change_user(%User{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"user" => user_params}) do
    case Accounts.create_user(user_params) do
      {:ok, _user} ->
        conn
        |> put_flash(:info, "User created successfully.")
        |> redirect(to: admin_user_path(conn, :index))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def edit(conn, %{"id" => id}) do
    user = Accounts.get_user!(id)
    changeset = Accounts.change_user(user)
    render(conn, "edit.html", user: user, changeset: changeset)
  end

  def update(conn, %{"id" => id, "user" => user_params}) do
    user = Accounts.get_user!(id)

    case Accounts.update_user(user, user_params) do
      {:ok, _user} ->
        conn
        |> put_flash(:info, "User updated successfully.")
        |> redirect(to: admin_user_path(conn, :index))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", user: user, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    user = Accounts.get_user!(id)
    {:ok, _user} = Accounts.delete_user(user)

    conn
    |> put_flash(:info, "User deleted successfully.")
    |> redirect(to: admin_user_path(conn, :index))
  end

	def deactivate(conn, %{"user_id" => user_id}) do
		user = Accounts.get_active_user!(user_id)
		{:ok, _user} = Accounts.deactivate_user(user)

		conn
		|> put_flash(:info, "User deactivated successfully.")
		|> redirect(to: admin_user_path(conn, :index))
	end

	def activate(conn, %{"user_id" => user_id}) do
		user = Accounts.get_user!(user_id)
		{:ok, _user} = Accounts.activate_user(user)

		conn
		|> put_flash(:info, "User activated successfully.")
		|> redirect(to: admin_user_path(conn, :index))
	end
end
