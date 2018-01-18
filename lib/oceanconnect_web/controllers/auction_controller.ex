defmodule OceanconnectWeb.AuctionController do
  use OceanconnectWeb, :controller
  alias Oceanconnect.Auctions
  alias Oceanconnect.Auctions.Auction
  alias Oceanconnect.Accounts.Auth

  def index(conn, _params) do
    auctions = Auctions.list_auctions()
    render(conn, "index.html", auctions: auctions)
  end

  def new(conn, _params) do
    changeset = Auctions.change_auction(%Auction{})
    ports = Auctions.list_ports
    vessels = Auctions.vessels_for_buyer(Auth.current_user(conn))
    fuels = Auctions.list_fuels
    render(conn, "new.html", changeset: changeset, auction: changeset.data, ports: ports, vessels: vessels, fuels: fuels)
  end

  def create(conn, %{"auction" => auction_params}) do
    auction_params = Auction.from_params(auction_params)
    |> Map.put("buyer_id", Auth.current_user(conn).id)
    case Auctions.create_auction(auction_params) do
      {:ok, auction} ->
        conn
        |> put_flash(:info, "Auction created successfully.")
        |> redirect(to: auction_path(conn, :show, auction))
      {:error, %Ecto.Changeset{} = changeset} ->
        auction = Ecto.Changeset.apply_changes(changeset)
        |> Auctions.fully_loaded
        ports = Auctions.list_ports
        vessels = Auctions.vessels_for_buyer(Auth.current_user(conn))
        fuels = Auctions.list_fuels
        render(conn, "new.html", changeset: changeset, ports: ports, auction: auction, vessels: vessels, fuels: fuels)
    end
  end

  def show(conn, %{"id" => id}) do
    auction = Auctions.get_auction!(id)
    |> Auctions.fully_loaded

    render(conn, "show.html", auction: auction)
  end

  def edit(conn, %{"id" => id}) do
    auction = Auctions.get_auction!(id)
    changeset = Auctions.change_auction(auction)
    ports = Auctions.list_ports
    vessels = Auctions.vessels_for_buyer(Auth.current_user(conn))
    fuels = Auctions.list_fuels

    render(conn, "edit.html", auction: auction, changeset: changeset, ports: ports, vessels: vessels, fuels: fuels)
  end

  def update(conn, %{"id" => id, "auction" => auction_params}) do
    auction = Auctions.get_auction!(id)
    auction_params = Auction.from_params(auction_params)

    case Auctions.update_auction(auction, auction_params) do
      {:ok, auction} ->
        conn
        |> put_flash(:info, "Auction updated successfully.")
        |> redirect(to: auction_path(conn, :show, auction))
      {:error, %Ecto.Changeset{} = changeset} ->
        auction = Ecto.Changeset.apply_changes(changeset)
        ports = Auctions.list_ports
        vessels = Auctions.vessels_for_buyer(Auth.current_user(conn))
        fuels = Auctions.list_fuels


        render(conn, "edit.html", auction: auction, changeset: changeset, ports: ports, vessels: vessels, fuels: fuels)
    end
  end
end
