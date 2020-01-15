defmodule OceanconnectWeb.Api.ObserverController do
  use OceanconnectWeb, :controller
  import Oceanconnect.Auctions.Guards

  alias OceanconnectWeb.Plugs.Auth
  alias Oceanconnect.Auctions
  alias Oceanconnect.Accounts
  alias Oceanconnect.Accounts.User
  alias Oceanconnect.Auctions.{AuctionNotifier, AuctionPayload}

  def invite(conn, %{"auction_id" => auction_id, "user_id" => user_id}) do
    with %{id: admin_id, is_admin: true} <- Auth.current_user(conn),
         %struct{} = auction when is_auction(struct) <- Auctions.get_auction(auction_id),
         %User{is_observer: true} = observer <-
           Enum.find(Accounts.list_observers(), &(&1.id == String.to_integer(user_id))) do
      Auctions.invite_observer(auction, observer)

      auction =
        auction.id
        |> Auctions.get_auction()
        |> Auctions.fully_loaded(true)

      AuctionNotifier.notify_participants(auction)

      conn
      |> render("invite.json", %{
        auction_payload: AuctionPayload.get_auction_payload!(auction, admin_id)
      })
    else
      _ ->
        conn
        |> put_status(422)
        |> render("show.json", %{succes: false, message: "Invalid observer"})
    end
  end

  def uninvite(conn, %{"auction_id" => auction_id, "user_id" => user_id}) do
    with %{id: admin_id, is_admin: true} <- Auth.current_user(conn),
         %struct{} = auction when is_auction(struct) <- Auctions.get_auction(auction_id),
         %User{is_observer: true, company_id: observer_company_id} = user <-
           Enum.find(Accounts.list_observers(), &(&1.id == String.to_integer(user_id))) do
      Auctions.uninvite_observer(auction, user)

      auction =
        auction.id
        |> Auctions.get_auction()
        |> Auctions.fully_loaded()

      AuctionNotifier.remove_observer(auction, observer_company_id)

      conn
      |> render("invite.json", %{
        auction_payload: AuctionPayload.get_auction_payload!(auction, admin_id)
      })
    else
      _ ->
        conn
        |> put_status(422)
        |> render("show.json", %{success: false, message: "Invalide observer"})
    end
  end
end
