defmodule OceanconnectWeb.Admin.UserController do
  use OceanconnectWeb, :controller

  alias Oceanconnect.Accounts
  alias Oceanconnect.Accounts.User
  alias Oceanconnect.Guardian

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
    companies = Accounts.list_active_companies()
    changeset = Accounts.change_user(%User{})
    render(conn, "new.html", changeset: changeset, companies: companies)
  end

  def create(conn, %{"user" => user_params}) do
    companies = Accounts.list_active_companies()

    case Accounts.admin_create_user(user_params) do
      {:ok, _user} ->
        conn
        |> put_flash(:info, "User created successfully.")
        |> redirect(to: admin_user_path(conn, :index))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset, companies: companies)
    end
  end

  def edit(conn, %{"id" => id}) do
    companies = Accounts.list_active_companies()
    user = Accounts.get_user!(id)
    changeset = Accounts.change_user(user)
    render(conn, "edit.html", user: user, changeset: changeset, companies: companies)
  end

  def update(conn, %{"id" => id, "user" => user_params}) do
    user = Accounts.get_user!(id)
    companies = Accounts.list_active_companies()

    case Accounts.admin_update_user(user, user_params) do
      {:ok, _user} ->
        conn
        |> put_flash(:info, "User updated successfully.")
        |> redirect(to: admin_user_path(conn, :index))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", user: user, changeset: changeset, companies: companies)
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

  def reset_password(conn, %{"user_id" => user_id}) do
    user = Accounts.get_user!(user_id)
    companies = Accounts.list_active_companies()
    changeset = Accounts.change_user(user)

    {:ok, token, _claims} =
      Guardian.encode_and_sign(user, %{user_id: user.id, email: true}, ttl: {1, :hours})

    Oceanconnect.Auctions.NonEventNotifier.emit(user, token)

    conn
    |> put_flash(
      :info,
      "An email has been sent to the user with instructions to reset their password"
    )
    |> put_status(200)
    |> render("edit.html", user: user, changeset: changeset, companies: companies)
  end
end
