defmodule OceanconnectWeb.Mailer do
  use Bamboo.Mailer, otp_app: :oceanconnect

  def deliver_2fa_email(user = %Oceanconnect.Accounts.User{has_2fa: true}, one_time_pass) do
    OceanconnectWeb.Email.two_factor_auth(user, one_time_pass)
    |> deliver_later()
  end
end
