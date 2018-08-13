defmodule Oceanconnect.Admin.Fuel.IndexPage do
	use Oceanconnect.Page

	@page_path "/admin/fuels"

	def visit do
		navigate_to(@page_path)
	end

	def is_current_path? do
		current_path() == @page_path
	end

	def has_fuels?(fuels) do
		fuels
		|> Enum.all?(fn(fuel) ->
			case search_element(:css, ".qa-admin-fuel-#{fuel.id}") do
				{:ok, _} -> true
				_ -> false
			end
		end)
	end

	def has_fuel?(id) do
		case search_element(:css, ".qa-admin-fuel-#{id}") do
			{:error, _} -> false
			_ -> true
		end
	end

	def has_fuel_name?(name) do
		fuel_name = find_element(:css, ".qa-admin-fuel-name")
		|> inner_text
		name == fuel_name
	end

	def deactivate_fuel(fuel) do
		find_element(:css, ".qa-admin-fuel-#{fuel.id}")
		|> find_within_element(:css, ".qa-admin-fuel-deactivate")
		|> click
	end

	def activate_fuel(fuel) do
		find_element(:css, ".qa-admin-fuel-#{fuel.id}")
		|> find_within_element(:css, ".qa-admin-fuel-activate")
		|> click
	end

	def is_fuel_active?(fuel) do
		find_element(:css, ".qa-admin-fuel-#{fuel.id}")
		|> search_within_element(:css, ".qa-admin-fuel-deactivate")
	end

	def is_fuel_inactive?(fuel) do
		find_element(:css, ".qa-admin-fuel-#{fuel.id}")
		|> search_within_element(:css, ".qa-admin-fuel-activate")
	end
end
