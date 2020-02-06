defmodule OceanconnectWeb.Email do
  use Oceanconnect.Notifications.Email
  alias Oceanconnect.Accounts.User

  def password_reset(%User{} = user, token) do
    base_email(user)
    |> subject("Reset your password")
    |> render(
      "password_reset.html",
      user: user,
      token: token
    )
  end

  def two_factor_auth(%User{has_2fa: true} = user, one_time_pass) do
    two_factor_email(user)
    |> subject("Two factor authentication")
    |> render(
      "two_factor_auth.html",
      user: user,
      one_time_pass: one_time_pass
    )
  end

  def user_interest(new_user_info) do
    user_interest_email()
    |> subject("An unregistered user is requesting more information")
    |> render(
      "user_interest.html",
      new_user_info: new_user_info
    )
  end
end
