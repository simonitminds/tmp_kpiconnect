defmodule Oceanconnect.Notifications.Emails.PasswordReset do
  use Oceanconnect.Notifications.Email
  alias Oceanconnect.Accounts.User

  def generate(user, token), do: emails(user, token)

  defp emails(user = %User{}, token) do
    base_email(user)
    |> subject("Reset your password")
    |> render(
      "password_reset.html",
      user: user,
      token: token
    )
    |> List.wrap()
  end
end
