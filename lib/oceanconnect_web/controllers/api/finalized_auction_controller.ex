defmodule OceanconnectWeb.Api.FinalizedAuctionController do
  use OceanconnectWeb, :controller

  alias OceanconnectWeb.Plugs.Auth
  alias Oceanconnect.Auctions
  alias Oceanconnect.Auctions.AuctionPayload
  alias Oceanconnect.Accounts.User

  def index(conn, _params) do
    with %User{company_id: current_user_company_id} <- Auth.current_user(conn) do
      auction_payloads =
        case Auth.current_user_is_admin?(conn) do
          true ->
            Auctions.list_finalized_auctions()
            |> Enum.map(fn auction ->
              auction
              |> Auctions.fully_loaded()
              |> AuctionPayload.get_admin_auction_payload!()
            end)
          false ->
            Auctions.list_participating_finalized_auctions(current_user_company_id)
            |> Enum.map(fn auction ->
              auction
              |> Auctions.fully_loaded()
              |> AuctionPayload.get_auction_payload!(current_user_company_id)
            end)
        end

      render(conn, "index.json", data: auction_payloads)
    end
  end
end
