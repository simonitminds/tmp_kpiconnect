defmodule Oceanconnect.Admin.Port.IndexPage do
	use Oceanconnect.Page

	@page_path "/admin/ports"

	def visit do
		navigate_to(@page_path)
	end

	def is_current_path? do
		current_path() == @page_path
	end

	def has_ports?(ports) do
		ports
		|> Enum.all?(fn(port) ->
			case search_element(:css, ".qa-admin-port-#{port.id}") do
				{:ok, _} -> true
				_ -> false
			end
		end)
	end

	def has_port?(id) do
		case search_element(:css, ".qa-admin-port-#{id}") do
			{:error, _} -> false
			_ -> true
		end
	end

	def has_port_name?(name) do
		port_name = find_element(:css, ".qa-admin-port-name")
		|> inner_text
		name == port_name
	end

	def deactivate_port(port) do
		find_element(:css, ".qa-admin-port-#{port.id}")
		|> find_within_element(:css, ".qa-admin-port-deactivate")
		|> click
	end

	def activate_port(port) do
		find_element(:css, ".qa-admin-port-#{port.id}")
		|> find_within_element(:css, ".qa-admin-port-activate")
		|> click
	end

	def is_port_active?(port) do
		find_element(:css, ".qa-admin-port-#{port.id}")
		|> search_within_element(:css, ".qa-admin-port-deactivate")
	end

	def is_port_inactive?(port) do
		find_element(:css, ".qa-admin-port-#{port.id}")
		|> search_within_element(:css, ".qa-admin-port-activate")
	end
end
