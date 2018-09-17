defmodule OceanconnectWeb.Admin.BargeView do
  use OceanconnectWeb, :view

  def barge_has_company?(%{companies: barge_companies}, %{id: company_id}) do
    if Enum.any?(barge_companies, fn barge_company ->
         barge_company.id == company_id
       end) do
      ""
    end
  end
end
