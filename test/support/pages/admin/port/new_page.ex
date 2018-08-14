defmodule Oceanconnect.Admin.Port.NewPage do
	use Oceanconnect.Page

	def visit do
		navigate_to("/admin/ports/new")
	end

	def is_current_path? do
		current_path() == "/admin/ports/new"
	end
end
