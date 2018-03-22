defmodule OceanconnectWeb.Api.AuctionController do
  use OceanconnectWeb, :controller
  alias Oceanconnect.Auctions

  def index(conn, %{"user_id" => user_id}) do
    auction_payloads = user_id
    |> Auctions.list_participating_auctions
    |> Enum.map(fn(auction) ->
      Auctions.AuctionPayload.get_auction_payload!(auction, String.to_integer(user_id))
    end)

    render(conn, "index.json", data: auction_payloads)
  end
end
