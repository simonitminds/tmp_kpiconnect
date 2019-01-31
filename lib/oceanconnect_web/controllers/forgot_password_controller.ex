defmodule OceanconnectWeb.ForgotPasswordController do
  use OceanconnectWeb, :controller
  import Plug.Conn

  alias Oceanconnect.Guardian
  alias Oceanconnect.Accounts

  def new(conn, _), do: render(conn, "forgot_password.html")

  def create(conn, %{"email" => email}) do
    case Accounts.get_user_by_email(String.upcase(email)) do
      nil ->
        conn
        |> put_status(302)
        |> redirect(to: session_path(conn, :new))
      user ->
        {:ok, token, _claims} =
          Guardian.encode_and_sign(user, %{user_id: user.id, email: true}, ttl: {1, :hours})

        OceanconnectWeb.Email.password_reset(user, token)
        |> OceanconnectWeb.Mailer.deliver_later()

        conn
        |> put_flash(:info, "An email has been sent with instructions to reset your password")
        |> put_status(302)
        |> redirect(to: session_path(conn, :new))
    end
  end

  def edit(conn, %{"token" => token}) do
    %{claims: %{"user_id" => user_id}} = Guardian.peek(token)
    user = Accounts.get_user!(user_id)

    case Guardian.decode_and_verify(token, %{user_id: user.id, email: true}) do
      {:ok, _claims} ->
        render(conn, "reset_password.html", token: token, user: user, action: forgot_password_path(conn, :update))
      {:error, _} ->
        conn
        |> put_flash(:error, "Please try resetting your password again")
        |> put_status(302)
        |> redirect(to: session_path(conn, :new))
    end
  end

  def update(conn, %{"password" => password, "password_confirmation" => password_confirmation, "token" => token}) do
    %{claims: %{"user_id" => user_id}} = Guardian.peek(token)
    user = Accounts.get_user!(user_id)

    case Accounts.reset_password(user, %{"password" => password, "password_confirmation" => password_confirmation}) do
      {:ok, _user} ->
        conn
        |> put_flash(:info, "Password updated successfully")
        |> put_status(302)
        |> redirect(to: session_path(conn, :new))
      {:error, _} ->
        conn
        |> put_flash(:error, "Passwords do not match")
        |> put_status(401)
        |> render("reset_password.html", token: token, user: user, action: forgot_password_path(conn, :update))
    end
  end
end
