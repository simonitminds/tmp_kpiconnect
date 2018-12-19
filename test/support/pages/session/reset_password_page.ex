defmodule Oceanconnect.Session.ResetPasswordPage do
  use Oceanconnect.Page

  def visit(user_id, token) do
    navigate_to("/reset_password?token=#{token}user_id=#{user_id}")
  end
end
