defmodule OceanconnectWeb.Admin.UserView do
  use OceanconnectWeb, :view

	def full_name(%Oceanconnect.Accounts.User{first_name: first_name, last_name: last_name}) do
		"#{first_name} #{last_name}"
	end
end
