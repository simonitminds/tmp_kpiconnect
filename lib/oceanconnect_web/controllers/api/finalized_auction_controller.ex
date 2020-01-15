defmodule OceanconnectWeb.Api.FinalizedAuctionController do
  use OceanconnectWeb, :controller

  alias OceanconnectWeb.Plugs.Auth
  alias Oceanconnect.Auctions
  alias Oceanconnect.Auctions.AuctionPayload
  alias Oceanconnect.Accounts.User

  def index(conn, _params) do
    user = %User{company_id: company_id} = Auth.current_user(conn)

    auction_payloads =
      user
      |> Auctions.list_finalized_auctions()
      |> Enum.map(fn auction ->
        auction
        |> Auctions.fully_loaded()
        |> AuctionPayload.get_auction_payload!(company_id)
      end)

    render(conn, "index.json", data: auction_payloads)
  end
end
