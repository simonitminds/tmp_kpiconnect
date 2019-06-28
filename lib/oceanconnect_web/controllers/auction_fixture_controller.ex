defmodule OceanconnectWeb.AuctionFixtureController do
  use OceanconnectWeb, :controller

  alias OceanconnectWeb.Plugs.Auth
  alias Oceanconnect.Auctions
  alias Oceanconnect.Auctions.{Auction, AuctionFixture}
  alias Oceanconnect.Deliveries

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def edit(conn, %{"auction_id" => auction_id, "fixture_id" => fixture_id}) do
    current_user = Auth.current_user(conn)

    with %Auction{buyer_id: buyer_id} = auction <-
           Auctions.get_auction!(auction_id),
         status when status in [:closed, :expired] <- Auctions.get_auction_status!(auction),
         %AuctionFixture{supplier_id: supplier_id} = fixture <- Auctions.get_fixture!(fixture_id),
         true <- current_user.company_id == buyer_id or current_user.company_id == supplier_id do
      is_buyer? = current_user.company_id == buyer_id

      changeset = Auctions.change_fixture(fixture)

      conn
      |> render("edit.html", %{
        auction: auction,
        fixture: fixture,
        changeset: changeset,
        suppliers: auction.suppliers,
        vessels: auction.vessels,
        fuels: Auctions.list_fuels(),
        is_buyer?: is_buyer?
      })
    else
      _ ->
        redirect(conn, to: auction_path(conn, :index))
    end
  end

  def propose_changes(conn, %{
        "auction_id" => auction_id,
        "fixture_id" => fixture_id,
        "auction_fixture" => fixture_params
      }) do
    current_user = Auth.current_user(conn)

    with %Auction{buyer_id: buyer_id} = auction <- Auctions.get_auction!(auction_id),
         status when status in [:closed, :expired] <- Auctions.get_auction_status!(auction),
         %AuctionFixture{supplier_id: supplier_id} = fixture <- Auctions.get_fixture!(fixture_id),
         true <- current_user.company_id == buyer_id or current_user.company_id == supplier_id do
      is_buyer? = current_user.company_id == buyer_id

      case Deliveries.propose_fixture_changes(fixture, fixture_params, current_user) do
        {:ok, _changeset} ->
          conn
          |> put_flash(:info, "Fixture changes proposed successfully.")
          |> redirect(to: auction_fixture_path(conn, :index))

        {:error, %Ecto.Changeset{} = changeset} ->
          render(conn, "edit.html",
            auction: auction,
            fixture: fixture,
            changeset: changeset,
            suppliers: auction.suppliers,
            vessels: auction.vessels,
            fuels: Auctions.list_fuels(),
            is_buyer?: is_buyer?
          )
      end
    else
      _ ->
        redirect(conn, to: auction_path(conn, :index))
    end
  end
end
