defmodule OceanconnectWeb.Admin.UserView do
  use OceanconnectWeb, :view

  def full_name(user), do: Oceanconnect.Accounts.get_user_name!(user)
end
