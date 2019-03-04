defmodule Oceanconnect.Admin.FuelIndex.NewPage do
  use Oceanconnect.Page

  def visit do
    navigate_to("/admin/fuel_index_entries/new")
  end

  def is_current_path? do
    current_path() == "/admin/fuel_index_entries/new"
  end
end

