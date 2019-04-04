defmodule OceanconnectWeb.AuctionRsvpController do
  use OceanconnectWeb, :controller
  import Oceanconnect.Auctions.Guards
  alias OceanconnectWeb.Plugs.Auth
  alias Oceanconnect.Auctions
  alias Oceanconnect.Auctions.{AuctionSuppliers, AuctionNotifier}
  alias Oceanconnect.Accounts.{User, Company}

  def update(conn, %{"id" => auction_id, "response" => response}) do
    with %User{company: %Company{id: company_id}} <- Auth.current_user(conn),
         %struct{} = auction when is_auction(struct) <-
           Auctions.get_auction(auction_id),
         %AuctionSuppliers{supplier_id: ^company_id} <-
           Auctions.get_auction_supplier(auction, company_id),
         true <- response in ["yes", "no", "maybe"] do
      Auctions.update_participation_for_supplier(auction, company_id, response)

      Auctions.get_auction!(auction_id)
      |> AuctionNotifier.notify_buyer_participants()

      conn
      |> redirect(to: auction_path(conn, :show, auction_id))
    else
      _error ->
        conn
        |> redirect(to: auction_path(conn, :index))
    end
  end
end
