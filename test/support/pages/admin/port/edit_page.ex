defmodule Oceanconnect.Admin.Port.EditPage do
	use Oceanconnect.Page

	def visit(id) do
		navigate_to("/admin/ports/#{id}/edit")
	end

	def has_fields?(fields) do
		Enum.all?(fields, fn field ->
			find_element(:css, ".qa-admin-port-#{field}")
		end)
	end

	def is_current_path?(id) do
		current_path() == "/admin/ports/#{id}/edit"
	end

	def submit do
		find_element(:css, ".qa-admin-submit")
		|> click
	end

	def delete do
		find_element(:css, ".qa-admin-delete")
		|> click
		Hound.Helpers.Dialog.accept_dialog
	end

	def fill_form(params = %{}) do
		params
		|> Enum.map(fn({key, value}) ->
			element = find_element(:css, ".qa-admin-port-#{key}")
			type = Hound.Helpers.Element.tag_name(element)
			fill_form_element(key, element, type, value)
		end)
	end

  def fill_form_element(_key, element, _type, value) do
    fill_field(element, value)
  end
end
