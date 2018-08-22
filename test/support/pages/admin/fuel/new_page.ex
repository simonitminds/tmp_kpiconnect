defmodule Oceanconnect.Admin.Fuel.NewPage do
  use Oceanconnect.Page

  def visit do
    navigate_to("/admin/fuels/new")
  end

  def is_current_path? do
    current_path() == "/admin/fuels/new"
  end
end
