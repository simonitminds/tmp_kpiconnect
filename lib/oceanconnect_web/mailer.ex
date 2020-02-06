defmodule OceanconnectWeb.Mailer do
  use Bamboo.Mailer, otp_app: :oceanconnect

  alias OceanconnectWeb.Email

  def deliver_2fa_email(user = %Oceanconnect.Accounts.User{has_2fa: true}, one_time_pass) do
    Email.two_factor_auth(user, one_time_pass)
    |> deliver_later()
  end

  def deliver_user_interest_email(new_user_info) do
    Email.user_interest(new_user_info)
    |> deliver_later()
  end

  def password_reset(user, token) do
    Email.password_reset(user, token)
    |> deliver_later()
  end
end
