defmodule OceanconnectWeb.Api.PortSupplierController do
  use OceanconnectWeb, :controller
  alias Oceanconnect.Auctions

  def index(conn, %{"port_id" => port_id}) do
    buyer_id = OceanconnectWeb.Plugs.Auth.current_user(conn).company_id
    port = Auctions.get_port!(String.to_integer(port_id))
    suppliers = Auctions.supplier_list_for_auction(port, buyer_id)

    render(conn, "index.json", suppliers: suppliers)
  end
end
