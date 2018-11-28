defmodule OceanconnectWeb.AuctionRsvpController do
  use OceanconnectWeb, :controller
  alias OceanconnectWeb.Plugs.Auth
  alias Oceanconnect.Auctions
  alias Oceanconnect.Auctions.{AuctionSuppliers, AuctionNotifier}
  alias Oceanconnect.Accounts.{User, Company}

  def update(conn, %{"id" => auction_id, "response" => response}) do
    with %User{company: %Company{id: company_id}} <- Auth.current_user(conn),
         %AuctionSuppliers{supplier_id: ^company_id} <-
           Auctions.get_auction_supplier(auction_id, company_id),
         true <- response in ["yes", "no", "maybe"] do
      Auctions.update_participation_for_supplier(auction_id, company_id, response)

      auction =
        Auctions.get_auction!(auction_id)
        |> Auctions.fully_loaded()

      AuctionNotifier.notify_buyer_participants(auction)

      conn
      |> redirect(to: auction_path(conn, :show, auction_id))
    else
      _error ->
        conn
        |> redirect(to: auction_path(conn, :index))
    end
  end
end
