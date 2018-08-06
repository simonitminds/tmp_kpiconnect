defmodule OceanconnectWeb.Api.SessionView do
  use OceanconnectWeb, :view
  alias Oceanconnect.Accounts.{User}

  def render("impersonate.json", %{data: {impersonated_user = %User{}, current_user = %User{}}}) do
    %{
      impersonating: impersonated_user.id,
      impersonated_by: current_user.id
    }
  end
end
