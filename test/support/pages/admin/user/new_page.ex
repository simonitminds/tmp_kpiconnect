defmodule Oceanconnect.Admin.User.NewPage do
  use Oceanconnect.Page

  def visit do
    navigate_to("/admin/users/new")
  end

  def is_current_path? do
    current_path() == "/admin/users/new"
  end
end
