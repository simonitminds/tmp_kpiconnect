defmodule OceanconnectWeb.EmailView do
  use OceanconnectWeb, :view

  def full_name(user) do
    "#{user.first_name} #{user.last_name}"
  end
end
