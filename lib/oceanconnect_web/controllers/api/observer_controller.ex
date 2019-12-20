defmodule OceanconnectWeb.Api.ObserverController do
  use OceanconnectWeb, :controller
  import Oceanconnect.Auctions.Guards

  alias OceanconnectWeb.Plugs.Auth
  alias Oceanconnect.Auctions
  alias Oceanconnect.Accounts
  alias Oceanconnect.Accounts.User
  alias Oceanconnect.Auctions.AuctionPayload

  def invite(conn, %{"auction_id" => auction_id, "user_id" => user_id}) do
    with %{id: admin_id, is_admin: true} <- Auth.current_user(conn),
         %struct{} = auction when is_auction(struct) <- Auctions.get_auction(auction_id),
         available_observers <- Accounts.list_observers(),
         %User{is_observer: true} = user <-
           Enum.find(available_observers, &(&1.id == String.to_integer(user_id))) do
      Auctions.invite_observer(auction, user)

      auction_payload =
        auction.id
        |> Auctions.get_auction()
        |> Auctions.fully_loaded()
        |> AuctionPayload.get_auction_payload!(admin_id)

      conn
      |> render("invite.json", %{auction_payload: auction_payload})
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
         available_observers <- Accounts.list_observers(),
         %User{is_observer: true} = user <-
           Enum.find(available_observers, &(&1.id == String.to_integer(user_id))) do
      Auctions.uninvite_observer(auction, user)

      auction_payload =
        auction.id
        |> Auctions.get_auction()
        |> Auctions.fully_loaded()
        |> AuctionPayload.get_auction_payload!(admin_id)

      conn
      |> render("invite.json", %{auction_payload: auction_payload})
    else
      _ ->
        conn
        |> put_status(422)
        |> render("show.json", %{success: false, message: "Invalide observer"})
    end
  end
end
