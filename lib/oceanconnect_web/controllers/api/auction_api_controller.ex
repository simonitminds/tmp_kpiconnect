defmodule OceanconnectWeb.Api.AuctionApiController do
  use OceanconnectWeb, :controller
  alias Oceanconnect.Auctions

  def index(conn, _params) do
    auctions = Auctions.list_auctions()
    |> Enum.map(fn(auction) ->
      Auctions.fully_loaded(auction)
    end)
    render(conn, "index.json", auctions: auctions)
  end
end
