defmodule Oceanconnect.Admin.Vessel.NewPage do
	use Oceanconnect.Page

	def visit do
		navigate_to("/admin/vessels/new")
	end

	def is_current_path? do
		current_path() == "/admin/vessels/new"
	end
end
