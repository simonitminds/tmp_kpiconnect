defmodule OceanconnectWeb.Api.FinalizedAuctionController do
  use OceanconnectWeb, :controller

  alias OceanconnectWeb.Plugs.Auth
  alias Oceanconnect.Auctions
  alias Oceanconnect.Auctions.AuctionPayload
  alias Oceanconnect.Accounts.User

  def index(conn, _params) do
    auction_payloads =
      case Auth.current_user(conn) do
        %User{id: admin_id, is_admin: true} ->
          Auctions.list_finalized_auctions()
          |> Enum.map(fn auction ->
            auction
            |> Auctions.fully_loaded()
            |> AuctionPayload.get_auction_payload!(admin_id)
          end)

        %User{id: observer_id, is_observer: true} = user ->
          Auctions.list_observing_auctions(user.id)
          |> Enum.map(fn auction ->
            auction
            |> Auctions.fully_loaded()
            |> AuctionPayload.get_auction_payload!(observer_id)
          end)

        user ->
          Auctions.list_participating_finalized_auctions(user.company_id)
          |> Enum.map(fn auction ->
            auction
            |> Auctions.fully_loaded()
            |> AuctionPayload.get_auction_payload!(user.company_id)
          end)
      end

    render(conn, "index.json", data: auction_payloads)
  end
end
