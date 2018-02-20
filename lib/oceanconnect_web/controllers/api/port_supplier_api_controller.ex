defmodule OceanconnectWeb.Api.PortSupplierController do
  use OceanconnectWeb, :controller
  alias Oceanconnect.Auctions

  def index(conn, %{"port_id" => port_id}) do
    id = String.to_integer(port_id)
    port = Auctions.get_port!(id)
    suppliers = Auctions.supplier_companies_for_port(port)

    render(conn, "index.json", suppliers: suppliers)
  end
end
