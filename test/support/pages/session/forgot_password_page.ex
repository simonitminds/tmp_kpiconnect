defmodule Oceanconnect.Session.ForgotPasswordPage do
  use Oceanconnect.Page

  @page_path "/forgot_password"

  def visit do
    navigate_to(@page_path)
  end

  def is_current_path? do
    current_path() == @page_path
  end

  def enter_email(email) do
    fill_field({:css, ".qa-forgot_password-email"}, email)
  end

  def submit do
    click({:css, ".qa-forgot_password-submit"})
  end
end
