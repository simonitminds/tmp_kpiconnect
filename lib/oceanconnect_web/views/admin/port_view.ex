defmodule OceanconnectWeb.Admin.PortView do
  use OceanconnectWeb, :view

  def port_has_company?(%{companies: port_companies}, %{id: company_id}) do
    if Enum.any?(port_companies, fn port_company ->
         port_company.id == company_id
        end) do
      true
    else
      false
    end
  end
end
