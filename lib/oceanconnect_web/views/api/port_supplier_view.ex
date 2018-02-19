defmodule OceanconnectWeb.Api.PortSupplierView do
  use OceanconnectWeb, :view

  def render("index.json", %{suppliers: suppliers}) do
    %{data: Enum.map(suppliers, fn(supplier) ->
         render(__MODULE__, "supplier.json", data: supplier)
       end)
  }
  end

  def render("supplier.json", %{data: supplier}) do
    %{
      id: supplier.id,
      name: supplier.name
    }
  end
end
