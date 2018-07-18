defmodule OceanconnectWeb.Api.CompanyBargesView do
  use OceanconnectWeb, :view

  def render("index.json", %{data: company_barges}) do
    %{data: company_barges}
  end
end
