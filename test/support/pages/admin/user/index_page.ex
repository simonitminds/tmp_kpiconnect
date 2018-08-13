defmodule Oceanconnect.Admin.User.IndexPage do
	use Oceanconnect.Page

	@page_path "/admin/users"

	def visit do
		navigate_to(@page_path)
	end

	def is_current_path? do
		current_path() == @page_path
	end

	def has_users?(users) do
		users
		|> Enum.all?(fn(user) ->
			case search_element(:css, ".qa-admin-user-#{user.id}") do
				{:ok, _} -> true
				_ -> false
			end
		end)
	end

	def has_user?(id) do
		case search_element(:css, ".qa-admin-user-#{id}") do
			{:error, _} -> false
			_ -> true
		end
	end

	def has_user_name?(name, id) do
		user_name = find_element(:css, ".qa-admin-user-#{id}")
		|> find_within_element(:css, ".qa-admin-user-full_name")
		|> inner_text
		name == user_name
	end

	def user_created_successfully? do
		page_text = visible_page_text()
		page_text =~ "User created successfully."
	end

	def deactivate_user(user) do
		find_element(:css, ".qa-admin-user-#{user.id}")
		|> find_within_element(:css, ".qa-admin-user-deactivate")
		|> click
	end

	def activate_user(user) do
		find_element(:css, ".qa-admin-user-#{user.id}")
		|> find_within_element(:css, ".qa-admin-user-activate")
		|> click
	end

	def is_user_active?(user) do
		find_element(:css, ".qa-admin-user-#{user.id}")
		|> search_within_element(:css, ".qa-admin-user-deactivate")
	end

	def is_user_inactive?(user) do
		find_element(:css, ".qa-admin-user-#{user.id}")
		|> search_within_element(:css, ".qa-admin-user-activate")
	end
end
