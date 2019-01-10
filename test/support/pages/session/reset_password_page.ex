defmodule Oceanconnect.Session.ResetPasswordPage do
  use Oceanconnect.Page

  def visit(token) do
    navigate_to("/reset_password?token=#{token}")
  end

  def is_current_path? do
    current_path() =~ "/reset_password"
  end

  def enter_credentials(password, password_confirmation, token) do
    fill_field({:css, ".qa-reset-password"}, password)
    fill_field({:css, ".qa-reset-password_confirmation"}, password_confirmation)
  end

  def submit do
    click({:css, ".qa-submit"})
  end
end
