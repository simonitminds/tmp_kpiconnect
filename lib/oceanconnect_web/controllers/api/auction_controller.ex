defmodule OceanconnectWeb.Api.AuctionController do
  use OceanconnectWeb, :controller
  alias Oceanconnect.Auctions

  def index(conn, %{"buyer_id" => buyer_id}) do
    auctions = Auctions.list_participating_auctions(buyer_id)
    |> Enum.map(fn(auction) ->
      Auctions.fully_loaded(auction)
    end)
    render(conn, "index.json", data: auctions)
  end
end
