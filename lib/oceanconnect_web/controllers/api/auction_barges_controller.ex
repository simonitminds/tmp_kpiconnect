defmodule OceanconnectWeb.Api.AuctionBargesController do
  use OceanconnectWeb, :controller
  alias Oceanconnect.Auctions

  def submit(conn, _params) do
    render(conn, "hi")
    # render(conn, "index.json", data: auction_payloads)
  end
end
