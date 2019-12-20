defmodule OceanconnectWeb.Api.AuctionController do
  use OceanconnectWeb, :controller
  alias Oceanconnect.Auctions
  alias Oceanconnect.Auctions.AuctionPayload
  alias Oceanconnect.Accounts.User
  alias OceanconnectWeb.Plugs.Auth

  def index(conn, _params) do
    auction_payloads =
      case Auth.current_user(conn) do
        %User{id: admin_id, is_admin: true} ->
          Auctions.list_auctions()
          |> Enum.map(fn auction ->
            auction
            |> Auctions.fully_loaded()
            |> AuctionPayload.get_auction_payload!(admin_id)
          end)

        %User{id: observer_id, is_observer: true} ->
          Auctions.list_observing_auctions(observer_id)
          |> Enum.map(fn auction ->
            auction
            |> Auctions.fully_loaded()
            |> AuctionPayload.get_auction_payload!(observer_id)
          end)

        user ->
          Auctions.list_participating_auctions(user.company_id)
          |> Enum.map(fn auction ->
            auction
            |> Auctions.fully_loaded()
            |> AuctionPayload.get_auction_payload!(user.company_id)
          end)
      end

    render(conn, "index.json", data: auction_payloads)
  end

  def show(conn, %{"auction_id" => auction_id}) do
    auction = Auctions.get_auction(auction_id)

    auction_payload =
      case Auth.current_user(conn) do
        %User{id: admin_id, is_admin: true} ->
          AuctionPayload.get_auction_payload!(auction, admin_id)

        %User{id: observer_id, is_observer: true} ->
          AuctionPayload.get_auction_payload!(auction, observer_id)

        user ->
          AuctionPayload.get_auction_payload!(auction, user.company_id)
      end

    render(conn, "show.json", data: auction_payload)
  end
end
