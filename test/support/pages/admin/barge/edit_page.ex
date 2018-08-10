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

	def has_barge?(id) do
		case search_element(:css, ".qa-admin-barge-#{id}") do
			{:error, _} -> false
			_ -> true
		end
	end

	def updated_barge_name do
		find_element(:css, ".qa-admin-barge-name")
		|> inner_text
	end

	def is_current_path?(id) do
		current_path() == "/admin/barges/#{id}/edit"
	end

	def is_index_path? do
		current_path() == "/admin/barges"
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
			element = find_element(:css, ".qa-admin-#{key}")
			type = Hound.Helpers.Element.tag_name(element)
			fill_form_element(key, element, type, value)
		end)
	end

  def fill_form_element(_key, element, _type, value) do
    fill_field(element, value)
  end
end
