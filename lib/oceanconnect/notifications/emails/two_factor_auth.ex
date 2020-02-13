defmodule Oceanconnect.Notifications.Emails.TwoFactorAuth do
  use Oceanconnect.Notifications.Email
  alias Oceanconnect.Accounts.User

  def generate(user, one_time_pass), do: emails(user, one_time_pass)

  defp emails(user = %User{has_2fa: true}, one_time_pass) do
    two_factor_email(user)
    |> subject("Two factor authentication")
    |> render(
      "two_factor_auth.html",
      user: user,
      one_time_pass: one_time_pass
    )
    |> List.wrap()
  end
end
