defmodule OceanconnectWeb.Api.AuctionController do
  use OceanconnectWeb, :controller
  alias Oceanconnect.Auctions

  def index(conn, _params) do
    user_id = OceanconnectWeb.Plugs.Auth.current_user(conn).company_id
    auction_payloads = user_id
    |> Auctions.list_participating_auctions
    |> Enum.map(fn(auction) ->
      Auctions.AuctionPayload.get_auction_payload!(auction, user_id)
    end)

    render(conn, "index.json", data: auction_payloads)
  end
end
