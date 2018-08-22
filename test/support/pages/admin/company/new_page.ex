defmodule Oceanconnect.Admin.Company.NewPage do
  use Oceanconnect.Page

  def visit do
    navigate_to("/admin/companies/new")
  end

  def is_current_path? do
    current_path() == "/admin/companies/new"
  end
end
