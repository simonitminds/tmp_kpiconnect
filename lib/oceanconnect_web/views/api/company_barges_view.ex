defmodule OceanconnectWeb.Api.CompanyBargesView do
  use OceanconnectWeb, :view

  def render("index.json", %{data: company_barges}) do
    embedded_barges =
      Enum.map(company_barges, fn barge ->
        %{barge | port: barge.port.name}
      end)

    %{data: embedded_barges}
  end
end
