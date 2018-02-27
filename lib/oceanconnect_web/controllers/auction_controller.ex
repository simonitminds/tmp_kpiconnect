defmodule OceanconnectWeb.AuctionController do
  use OceanconnectWeb, :controller
  alias Oceanconnect.Auctions
  alias Oceanconnect.Auctions.Auction
  alias OceanconnectWeb.Plugs.Auth

  def index(conn, _params) do
    user = Auth.current_user(conn)
    auctions = Auctions.list_participating_auctions(user.company_id)
    render(conn, "index.html", auctions: auctions)
  end

  def start(conn, %{"id" => id}) do
    id
    |> Auctions.get_auction!
    |> Auctions.start_auction

    redirect(conn, to: auction_path(conn, :index))
  end

  def new(conn, _params) do
    changeset = Auctions.change_auction(%Auction{})
    [fuels, ports, vessels] = auction_inputs_by_buyer(conn)
    json_auction = %Auction{}
    |> Auctions.strip_non_loaded
    |> Poison.encode!

    render(conn, "new.html", changeset: changeset, json_auction: json_auction,
      fuels: fuels, ports: ports, vessels: vessels, suppliers: Poison.encode!([]))
  end

  def create(conn, %{"auction" => auction_params}) do
    auction_params = Auction.from_params(auction_params)
    |> Map.put("buyer_id", Auth.current_user(conn).company.id)
    case Auctions.create_auction(auction_params) do
      {:ok, auction} ->
        conn
        |> put_flash(:info, "Auction created successfully.")
        |> redirect(to: auction_path(conn, :show, auction))
      {:error, %Ecto.Changeset{} = changeset} ->
        auction = Ecto.Changeset.apply_changes(changeset)
        |> Auctions.fully_loaded

        [fuels, ports, vessels] = auction_inputs_by_buyer(conn)
        json_auction = auction
        |> Auctions.fully_loaded
        |> Poison.encode!

        render(conn, "new.html", changeset: changeset, auction: auction, json_auction: json_auction,
          fuels: fuels, ports: ports, vessels: vessels, suppliers: Poison.encode!([]))
    end
  end

  def show(conn, %{"id" => id}) do
    auction = Auctions.get_auction!(id)
    |> Auctions.fully_loaded
    if Auctions.is_participant?(auction, Auth.current_user(conn).company_id) do
      render(conn, "show.html", auction: auction)
    else
      redirect(conn, to: auction_path(conn, :index))
    end
  end

  def edit(conn, %{"id" => id}) do
    auction = id
    |> Auctions.get_auction!
    |> Auctions.fully_loaded

    if(auction.buyer_id != Auth.current_user(conn).company_id) do
      redirect(conn, to: auction_path(conn, :index))
    else
      suppliers = case auction.port do
        nil -> []
        _ ->
          auction.port
          |> Auctions.supplier_companies_for_port
          |> Poison.encode!
      end
      changeset = Auctions.change_auction(auction)
      [fuels, ports, vessels] = auction_inputs_by_buyer(conn)
      json_auction = auction
      |> Poison.encode!

      render(conn, "edit.html", changeset: changeset, auction: auction, json_auction: json_auction,
        fuels: fuels, ports: ports, vessels: vessels, suppliers: suppliers)
    end
  end

  def update(conn, %{"id" => id, "auction" => auction_params}) do
    auction = id
    |> Auctions.get_auction!
    |> Auctions.fully_loaded
    auction_params = Auction.from_params(auction_params)
    if(auction.buyer_id != Auth.current_user(conn).company_id) do
      redirect(conn, to: auction_path(conn, :index))
    else
      case Auctions.update_auction(auction, auction_params) do
        {:ok, auction} ->
          conn
          |> put_flash(:info, "Auction updated successfully.")
          |> redirect(to: auction_path(conn, :show, auction))
        {:error, %Ecto.Changeset{} = changeset} ->
          auction = Ecto.Changeset.apply_changes(changeset)
          |> Auctions.fully_loaded
          suppliers = case auction.port do
            nil -> []
            _ ->
              auction.port
              |> Auctions.supplier_companies_for_port
              |> Poison.encode!
          end
          [fuels, ports, vessels] = auction_inputs_by_buyer(conn)
          json_auction = auction
          |> Auctions.fully_loaded
          |> Poison.encode!

          render(conn, "edit.html", changeset: changeset, auction: auction, json_auction: json_auction,
            fuels: fuels, ports: ports, vessels: vessels, suppliers: suppliers)
      end
    end
  end

  defp auction_inputs_by_buyer(conn) do
    buyer = Auth.current_user(conn)
    fuels = Auctions.list_fuels()
    ports = Auctions.ports_for_company(buyer.company)
    vessels = Auctions.vessels_for_buyer(buyer.company)
    Enum.map([fuels, ports, vessels], fn(list) ->
      list |> Poison.encode!
    end)
  end
end
