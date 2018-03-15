defmodule OceanconnectWeb.Api.AuctionController do
  use OceanconnectWeb, :controller
  alias Oceanconnect.Auctions

  def index(conn, %{"user_id" => user_id}) do
    auction_payloads = Auctions.list_participating_auctions(user_id)
    |> Enum.map(fn(auction) ->
      loaded_auction = auction
      |> Auctions.fully_loaded
      auction_payload = loaded_auction
      |> Auctions.get_auction_state
      |> Auctions.build_auction_state_payload(user_id)
      Map.merge(auction_payload, loaded_auction)
    end)

    render(conn, "index.json", data: auction_payloads)
  end
end
