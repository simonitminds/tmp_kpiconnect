defmodule OceanconnectWeb.AuctionController do
  use OceanconnectWeb, :controller
  alias Oceanconnect.Auctions
  alias Oceanconnect.Auctions.{Auction, AuctionEventStore, AuctionPayload}
  alias OceanconnectWeb.Plugs.Auth

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def log(conn, %{"id" => id}) do
    current_company_id = OceanconnectWeb.Plugs.Auth.current_user(conn).company_id

    auction =
      id
      |> Auctions.get_auction!()
      |> Auctions.fully_loaded()

    with %Auction{} <- auction,
         true <- current_company_id == auction.buyer_id,
         false <- Auctions.get_auction_state!(auction).status in [:pending, :open, :draft] do
      events =
        auction.id
        |> AuctionEventStore.event_list()

      auction_payload = AuctionPayload.get_auction_payload!(auction, auction.buyer_id)

      render(conn, "log.html", auction_payload: auction_payload, events: events)
    else
      _ ->
        if(Auth.current_admin(conn)) do
          events =
            auction.id
            |> AuctionEventStore.event_list()

          auction_payload = AuctionPayload.get_auction_payload!(auction, auction.buyer_id)

          render(conn, "log.html", auction_payload: auction_payload, events: events)
        else
          redirect(conn, to: auction_path(conn, :index))
        end
    end
  end

  def start(conn, %{"id" => id}) do
    admin = Auth.current_admin(conn)

    if admin do
      id
      |> Auctions.get_auction!()
      |> Auctions.fully_loaded()
      |> Auctions.start_auction(admin)
    end

    redirect(conn, to: auction_path(conn, :index))
  end

  def cancel(conn, %{"id" => id}) do
    user = Auth.current_user(conn)

    id
    |> Auctions.get_auction!()
    |> Auctions.fully_loaded()
    |> Auctions.cancel_auction(user)

    redirect(conn, to: auction_path(conn, :index))
  end

  def new(conn, _params) do
    user = Auth.current_user(conn)
    credit_margin_amount = user.company.credit_margin_amount
    changeset = Auctions.change_auction(%Auction{})
    [fuels, ports, vessels] = auction_inputs_by_buyer(conn)

    render(
      conn,
      "new.html",
      changeset: changeset,
      auction: %Auction{},
      fuels: fuels,
      ports: ports,
      vessels: vessels,
      suppliers: Poison.encode!([]),
      credit_margin_amount: credit_margin_amount
    )
  end

  def create(conn, %{"auction" => auction_params}) do
    auction_vessel_fuels =
      convert_auction_vessel_fuels_to_list(auction_params["auction_vessel_fuels"])

    user = Auth.current_user(conn)
    credit_margin_amount = user.company.credit_margin_amount

    updated_params =
      auction_params
      |> Auction.from_params()
      |> Map.put("buyer_id", user.company.id)
      |> Map.put("auction_vessel_fuels", auction_vessel_fuels)

    case Auctions.create_auction(updated_params, user) do
      {:ok, auction} ->
        conn
        |> put_flash(:info, "Auction created successfully.")
        |> redirect(to: auction_path(conn, :show, auction))

      {:error, %Ecto.Changeset{} = changeset} ->
        [auction, json_auction, suppliers] = build_payload_from_changeset(changeset)
        [fuels, ports, vessels] = auction_inputs_by_buyer(conn)

        render(
          conn,
          "new.html",
          changeset: changeset,
          auction: auction,
          json_auction: json_auction,
          fuels: fuels,
          ports: ports,
          vessels: vessels,
          suppliers: suppliers,
          credit_margin_amount: credit_margin_amount
        )
    end
  end

  def show(conn, %{"id" => id}) do
    auction = Auctions.get_auction!(id)
    user = Auth.current_user(conn)
    credit_margin_amount = user.company.credit_margin_amount

    if Auctions.is_participant?(auction, Auth.current_user(conn).company_id) do
      render(conn, "show.html", auction: auction, credit_margin_amount: credit_margin_amount)
    else
      redirect(conn, to: auction_path(conn, :index))
    end
  end

  def edit(conn, %{"id" => id}) do
    with auction = %Auction{} <- id |> Auctions.get_auction() |> Auctions.fully_loaded(),
         true <- auction.buyer_id == Auth.current_user(conn).company_id,
         false <- Auctions.get_auction_state!(auction).status in [:open, :decision] do
      changeset = Auctions.change_auction(auction)
      [auction, json_auction, suppliers] = build_payload_from_changeset(changeset)
      [fuels, ports, vessels] = auction_inputs_by_buyer(conn)

      user = Auth.current_user(conn)
      credit_margin_amount = user.company.credit_margin_amount

      render(
        conn,
        "edit.html",
        changeset: changeset,
        auction: auction,
        json_auction: json_auction,
        fuels: fuels,
        ports: ports,
        vessels: vessels,
        suppliers: suppliers,
        credit_margin_amount: credit_margin_amount
      )
    else
      _ -> redirect(conn, to: auction_path(conn, :index))
    end
  end

  def update(conn, %{"id" => id, "auction" => auction_params}) do
    auction_vessel_fuels =
      convert_auction_vessel_fuels_to_list(auction_params["auction_vessel_fuels"])

    user = Auth.current_user(conn)

    with auction = %Auction{} <- id |> Auctions.get_auction() |> Auctions.fully_loaded(),
         true <- auction.buyer_id == user.company_id,
         false <- Auctions.get_auction_state!(auction).status in [:open, :decision] do
      updated_params = Auction.from_params(auction_params)
      |> Map.put("auction_vessel_fuels", auction_vessel_fuels)

      case Auctions.update_auction(auction, updated_params, user) do
        {:ok, auction} ->
          conn
          |> put_flash(:info, "Auction updated successfully.")
          |> redirect(to: auction_path(conn, :show, auction))

        {:error, %Ecto.Changeset{} = changeset} ->
          [auction, json_auction, suppliers] = build_payload_from_changeset(changeset)
          [fuels, ports, vessels] = auction_inputs_by_buyer(conn)
          credit_margin_amount = user.company.credit_margin_amount

          render(
            conn,
            "edit.html",
            changeset: changeset,
            auction: auction,
            json_auction: json_auction,
            fuels: fuels,
            ports: ports,
            vessels: vessels,
            suppliers: suppliers,
            credit_margin_amount: credit_margin_amount
          )
      end
    else
      _ -> redirect(conn, to: auction_path(conn, :index))
    end
  end

  defp auction_inputs_by_buyer(conn) do
    buyer = Auth.current_user(conn)
    buyer_company = buyer.company
    fuels = Auctions.list_fuels()
    ports = Auctions.ports_for_company(buyer_company)
    vessels = Auctions.vessels_for_buyer(buyer_company)

    Enum.map([fuels, ports, vessels], fn list ->
      list |> Poison.encode!()
    end)
  end

  defp build_payload_from_changeset(changeset = %Ecto.Changeset{}) do
    auction =
      Ecto.Changeset.apply_changes(changeset)
      |> Auctions.fully_loaded()

    suppliers =
      case auction.port do
        nil ->
          []

        _ ->
          auction.port
          |> Auctions.supplier_list_for_auction(auction.buyer_id)
          |> Poison.encode!()
      end

    json_auction =
      auction
      |> Auctions.fully_loaded()
      |> Poison.encode!()

    [auction, json_auction, suppliers]
  end

  defp convert_auction_vessel_fuels_to_list(auction_vessel_fuels)
       when is_map(auction_vessel_fuels) do
    Enum.map(auction_vessel_fuels, fn {_, values} -> values end)
  end

  defp convert_auction_vessel_fuels_to_list(auction_vessel_fuels)
       when is_list(auction_vessel_fuels) do
    auction_vessel_fuels
  end

  defp convert_auction_vessel_fuels_to_list(_), do: []
end
