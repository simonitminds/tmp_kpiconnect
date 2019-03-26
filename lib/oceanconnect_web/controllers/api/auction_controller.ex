defmodule OceanconnectWeb.Api.AuctionController do
  use OceanconnectWeb, :controller
  alias Oceanconnect.Auctions
  alias Oceanconnect.Auctions.{AuctionPayload}
  alias OceanconnectWeb.Plugs.Auth

  def index(conn, _params) do
    user_id = Auth.current_user(conn).company_id

    auction_payloads =
      case Auth.current_user_is_admin?(conn) do
        true ->
          Auctions.list_auctions()
          |> Enum.map(fn auction ->
            auction
            |> Auctions.fully_loaded()
            |> AuctionPayload.get_admin_auction_payload!()
          end)

        false ->
          Auctions.list_participating_auctions(user_id)
          |> Enum.map(fn auction ->
            auction
            |> Auctions.fully_loaded()
            |> AuctionPayload.get_auction_payload!(user_id)
          end)
      end

    render(conn, "index.json", data: auction_payloads)
  end

  def show(conn, %{"auction_id" => auction_id}) do
    user_id = OceanconnectWeb.Plugs.Auth.current_user(conn).company_id
    auction = Auctions.get_auction(auction_id)

    auction_payload =
      case OceanconnectWeb.Plugs.Auth.current_user_is_admin?(conn) do
        true -> Auctions.AuctionPayload.get_admin_auction_payload!(auction)
        false -> Auctions.AuctionPayload.get_auction_payload!(auction, user_id)
      end

    render(conn, "show.json", data: auction_payload)
  end
end
