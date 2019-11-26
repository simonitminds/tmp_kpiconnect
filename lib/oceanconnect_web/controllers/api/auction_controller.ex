defmodule OceanconnectWeb.Api.AuctionController do
  use OceanconnectWeb, :controller
  alias Oceanconnect.Auctions
  alias Oceanconnect.Auctions.AuctionPayload
  alias Oceanconnect.Accounts.User
  alias OceanconnectWeb.Plugs.Auth

  def index(conn, _params) do
    auction_payloads =
      case Auth.current_user(conn) do
        %User{is_admin: true} ->
          Auctions.list_auctions()
          |> Enum.map(fn auction ->
            auction
            |> Auctions.fully_loaded()
            |> AuctionPayload.get_admin_auction_payload!()
          end)

        %User{is_observer: true} = user ->
          Auctions.list_observing_auctions(user.id)
          |> Enum.map(fn auction ->
            auction
            |> Auctions.fully_loaded()
            |> AuctionPayload.get_observer_auction_payload!()
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
        %User{is_admin: true} ->
          AuctionPayload.get_admin_auction_payload!(auction)

        %User{is_observer: true} ->
          AuctionPayload.get_observer_auction_payload!(auction)

        user ->
          AuctionPayload.get_auction_payload!(auction, user.company_id)
      end

    render(conn, "show.json", data: auction_payload)
  end
end
