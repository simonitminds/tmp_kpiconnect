defmodule Oceanconnect.Session.TwoFactorAuthPage do
  use Oceanconnect.Page

  def is_current_path? do
    current_path() == "/sessions/new/two_factor_auth"
  end

  def enter_credentials(one_time_pass) do
    fill_field({:css, ".qa-one_time_password"}, one_time_pass)
  end

  def submit do
    click({:css, ".qa-submit"})
  end

  def resend_2fa_email do
    click({:css, ".qa-resend_2fa_email"})
  end
end
