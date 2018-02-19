defmodule OceanconnectWeb.Api.AuctionController do
  use OceanconnectWeb, :controller
  alias Oceanconnect.Auctions

  def index(conn, _params) do
    auctions = Auctions.list_auctions()
    |> Enum.map(fn(auction) ->
      Auctions.fully_loaded(auction)
    end)
    render(conn, "index.json", data: auctions)
  end
end
