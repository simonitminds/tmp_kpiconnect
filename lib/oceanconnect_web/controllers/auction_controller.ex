defmodule OceanconnectWeb.AuctionController do
  use OceanconnectWeb, :controller
  alias Oceanconnect.Auctions
  alias Oceanconnect.Auctions.Auction

  def index(conn, _params) do
    auctions = Auctions.list_auctions()
    render(conn, "index.html", auctions: auctions)
  end

  def new(conn, _params) do
    changeset = Auctions.change_auction(%Auction{})
    auction = Auctions.with_port(changeset.data)
    ports = Auctions.list_ports
    render(conn, "new.html", changeset: changeset, ports: ports, auction: auction)
  end

  def create(conn, %{"auction" => auction_params}) do
    auction_params = Auction.from_params(auction_params)
    case Auctions.create_auction(auction_params) do
      {:ok, auction} ->
        conn
        |> put_flash(:info, "Auction created successfully.")
        |> redirect(to: auction_path(conn, :show, auction))
      {:error, %Ecto.Changeset{} = changeset} ->
        auction = Auctions.with_port(changeset.data)
        ports = Auctions.list_ports
        render(conn, "new.html", changeset: changeset, ports: ports, auction: auction)
    end
  end

  def show(conn, %{"id" => id}) do
    auction = Auctions.get_auction!(id)
    |> Auctions.with_port

    render(conn, "show.html", auction: auction)
  end

  def edit(conn, %{"id" => id}) do
    auction = Auctions.get_auction!(id)
    |> Auctions.with_port
    changeset = Auctions.change_auction(auction)

    ports = Auctions.list_ports

    render(conn, "edit.html", auction: auction, changeset: changeset, ports: ports)
  end

  def update(conn, %{"id" => id, "auction" => auction_params}) do
    auction = Auctions.get_auction!(id)
      |> Auctions.with_port
    auction_params = Auction.from_params(auction_params)

    case Auctions.update_auction(auction, auction_params) do
      {:ok, auction} ->
        conn
        |> put_flash(:info, "Auction updated successfully.")
        |> redirect(to: auction_path(conn, :show, auction))
      {:error, %Ecto.Changeset{} = changeset} ->
        ports = Auctions.list_ports
        render(conn, "edit.html", auction: auction, changeset: changeset, ports: ports)
    end
  end

  def delete(conn, %{"id" => id}) do
    auction = Auctions.get_auction!(id)
    {:ok, _auction} = Auctions.delete_auction(auction)

    conn
    |> put_flash(:info, "Auction deleted successfully.")
    |> redirect(to: auction_path(conn, :index))
  end
end
