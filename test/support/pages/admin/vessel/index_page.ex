defmodule Oceanconnect.Admin.Vessel.IndexPage do
	use Oceanconnect.Page

	@page_path "/admin/vessels"

	def visit do
		navigate_to(@page_path)
	end

	def is_current_path? do
		current_path() == @page_path
	end

	def has_vessels?(vessels) do
		vessels
		|> Enum.all?(fn(vessel) ->
			case search_element(:css, ".qa-admin-vessel-#{vessel.id}") do
				{:ok, _} -> true
				_ -> false
			end
		end)
	end

	def has_vessel?(id) do
		case search_element(:css, ".qa-admin-vessel-#{id}") do
			{:error, _} -> false
			_ -> true
		end
	end

	def has_vessel_name?(name) do
		vessel_name = find_element(:css, ".qa-admin-vessel-name")
		|> inner_text
		name == vessel_name
	end

	def deactivate_vessel(vessel) do
		find_element(:css, ".qa-admin-vessel-#{vessel.id}")
		|> find_within_element(:css, ".qa-admin-vessel-deactivate")
		|> click
	end

	def activate_vessel(vessel) do
		find_element(:css, ".qa-admin-vessel-#{vessel.id}")
		|> find_within_element(:css, ".qa-admin-vessel-activate")
		|> click
	end

	def is_vessel_active?(vessel) do
		find_element(:css, ".qa-admin-vessel-#{vessel.id}")
		|> search_within_element(:css, ".qa-admin-vessel-deactivate")
	end

	def is_vessel_inactive?(vessel) do
		find_element(:css, ".qa-admin-vessel-#{vessel.id}")
		|> search_within_element(:css, ".qa-admin-vessel-activate")
	end
end
