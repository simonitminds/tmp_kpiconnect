defmodule OceanconnectWeb.SessionController do
  use OceanconnectWeb, :controller
  import Plug.Conn
  alias Oceanconnect.Accounts
  alias Oceanconnect.Accounts.User
  alias OceanconnectWeb.Plugs.Auth
  # TODO: break this out eventually and put guardian shit in auth ^^
  alias Oceanconnect.Guardian

  def new(conn, _) do
    render(conn, "new.html")
  end

  def create(conn, %{"session" => session}) do
    case Accounts.verify_login(session) do
      {:ok, user} ->
        updated_conn =
          conn
          |> Auth.build_session(user)

        updated_conn
        |> redirect(to: auction_path(updated_conn, :index))

      {:error, _} ->
        conn
        |> put_flash(:error, "Invalid email/password")
        |> put_status(401)
        |> render("new.html")
    end
  end

  def delete(conn, _) do
    conn
    |> Auth.browser_logout()
    |> put_status(302)
    |> redirect(to: session_path(conn, :new))
  end

  def stop_impersonating(conn, _params) do
    updated_conn = Auth.stop_impersonating(conn)

    updated_conn
    |> redirect(to: auction_path(updated_conn, :index))
  end

  def already_authenticated(conn, _) do
    conn
    |> put_status(302)
    |> redirect(to: auction_path(conn, :index))
  end

  def auth_error(conn = %Plug.Conn{request_path: path}, {_type, _reason}, _opts) do
    case String.match?(path, ~r/\/api\//) do
      true ->
        conn
        |> put_status(401)
        |> render(OceanconnectWeb.ErrorView, "401.json", data: %{})

      false ->
        conn
        |> put_flash(:error, "Authentication Required")
        |> put_status(302)
        |> redirect(to: session_path(conn, :new))
    end
  end

  def forgot_password(conn, %{"email" => email}) do
    case Accounts.get_user_by_email(String.upcase(email)) |> IO.inspect do
      user ->
        {:ok, token, claims} =
          Guardian.encode_and_sign(user, %{email: true}, ttl: {1, :hours})

        OceanconnectWeb.Email.password_reset(user, token)
        |> OceanconnectWeb.Mailer.deliver_later()

        conn
        |> put_flash(:info, "An email has been sent with instructions to reset your password")
        |> redirect(to: session_path(conn, :new))
      nil ->
        conn
        |> put_status(403)
        |> render("forgot_password.html")
    end


    # cond do
    #   User.email_exists?(email) ->
    #     OceanconnectWeb.Email.password_reset(email)
    #     |> OceanconnectWeb.Mailer.deliver_later()

    #     conn
    #     |> put_flash(:info, "An email has been sent with instructions to reset your password")
    #     |> redirect(to: session_path(conn, :new))
    #   true ->
    #     conn
    #     |> put_flash(:error, "That email address does not exist in the system")
    #     |> put_status(401)
    #     |> render("forgot_password.html")
    # end
  end

  def forgot_password(conn, _) do
    render(conn, "forgot_password.html")
  end

  def reset_password(conn, %{"id" => id, "new_password" => new_password, "token" => token}) do
    user = Accounts.get_user!(id)

    case Accounts.reset_passwor(user, %{password: new_password}) do
      {:ok, _user} ->
        conn
        |> put_flash(:info, "Password updated successfully")
        |> redirect(to: session_path(conn, :new))

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_flash(:error, "Something went wrong!")
        |> put_status(401)
        |> render("reset_password.html", changeset: changeset, action: session_path(conn, :reset_password, %{user: user, token: token}))
    end
  end

  def reset_password(conn, %{"user_id" => user_id, "token" => token}) do
    user = Accounts.get_user!(user_id)

    case Guardian.decode_and_verify(token, %{email: true}) do
      {:ok, _claims} ->
        changeset = Accounts.change_user_password(user)

        render(conn, "reset_password.html", changeset: changeset, action: session_path(conn, :reset_password))
      {:error, _} ->
    end
  end

  def reset_password(conn, _) do
    conn
    |> redirect(to: session_path(conn, :new))
  end
end
