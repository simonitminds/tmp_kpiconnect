defmodule Oceanconnect.Admin.Barge.NewPage do
  use Oceanconnect.Page

  def visit do
    navigate_to("/admin/barges/new")
  end

  def is_current_path? do
    current_path() == "/admin/barges/new"
  end
end
