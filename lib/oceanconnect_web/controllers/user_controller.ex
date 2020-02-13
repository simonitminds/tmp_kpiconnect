defmodule OceanconnectWeb.UserController do
  use OceanconnectWeb, :controller

  alias Oceanconnect.Accounts
  alias Oceanconnect.Accounts.User
  alias OceanconnectWeb.Plugs.Auth
  alias Oceanconnect.Guardian

  def edit(conn, %{"id" => id}) do
    current_user = Auth.current_user(conn)
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

  def reset_password(conn, %{"user_id" => user_id}) do
    int_id = String.to_integer(user_id)
    %User{id: ^int_id} = Auth.current_user(conn)
    user = Accounts.get_user!(user_id)

    changeset = Accounts.change_user(user)

    {:ok, token, _claims} =
      Guardian.encode_and_sign(user, %{user_id: user.id, email: true}, ttl: {1, :hours})

    Oceanconnect.Auctions.NonEventNotifier.emit(user, token)

    conn
    |> put_flash(:info, "An email has been sent with instructions to reset your password")
    |> put_status(200)
    |> render("edit.html", user: user, changeset: changeset)
  end
end
