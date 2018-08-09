defmodule Oceanconnect.Admin.Barge.EditPage do
	use Oceanconnect.Page

	def visit(id) do
		navigate_to("/admin/barges/#{id}/edit")
	end

	def has_fields?(fields) do
		Enum.all?(fields, fn field ->
			find_element(:css, ".qa-admin-#{field}")
		end)
	end
end
