defmodule OceanconnectWeb.AuctionController do
  use OceanconnectWeb, :controller
  alias Oceanconnect.{Auctions, Messages}
  alias Oceanconnect.Auctions.{Auction, AuctionEventStore, AuctionPayload, Payloads}
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

    auction_state = Auctions.get_auction_state!(auction)

    with %Auction{} <- auction,
         true <- current_company_id == auction.buyer_id or Auth.current_user_is_admin?(conn),
         true <-
           auction_state.status not in [:draft, :pending, :open] or
             Auth.current_user_is_admin?(conn) do
      render(
        conn,
        "log.html",
        auction_payload: AuctionPayload.get_auction_payload!(auction, auction.buyer_id),
        events: AuctionEventStore.event_list(auction.id),
        messages_by_company: Messages.messages_by_thread(auction),
        solutions_payload:
          Payloads.SolutionsPayload.get_solutions_payload!(
            auction_state,
            auction: auction,
            buyer: auction.buyer_id
          )
      )
    else
      _ -> redirect(conn, to: auction_path(conn, :index))
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
    auction_vessel_fuels = vessel_fuels_from_params(auction_params)

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
      _ ->
        redirect(conn, to: auction_path(conn, :index))
    end
  end

  def update(conn, %{"id" => id, "auction" => auction_params}) do
    auction_vessel_fuels = vessel_fuels_from_params(auction_params)

    user = Auth.current_user(conn)

    with auction = %Auction{} <- id |> Auctions.get_auction() |> Auctions.fully_loaded(),
         true <- auction.buyer_id == user.company_id,
         false <- Auctions.get_auction_state!(auction).status in [:open, :decision] do
      updated_params =
        Auction.from_params(auction_params)
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
      _ ->
        redirect(conn, to: auction_path(conn, :index))
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
          |> Auctions.supplier_list_for_port(auction.buyer_id)
          |> Poison.encode!()
      end

    json_auction =
      auction
      |> Auctions.fully_loaded()
      |> Poison.encode!()

    [auction, json_auction, suppliers]
  end

  defp vessel_fuels_from_params(%{"auction_vessel_fuels" => auction_vessel_fuels})
       when is_map(auction_vessel_fuels) do
    Enum.flat_map(auction_vessel_fuels, fn {fuel_id, vessel_quantities} ->
      Enum.map(vessel_quantities, fn {vessel_id, quantity} ->
        %{"fuel_id" => fuel_id, "vessel_id" => vessel_id, "quantity" => quantity}
      end)
    end)
  end

  defp vessel_fuels_from_params(%{"auction_vessel_fuels" => auction_vessel_fuels})
       when is_list(auction_vessel_fuels) do
    auction_vessel_fuels
  end

  # For draft auctions, there might only be vessels or fuels provided. Even
  # though these are invalid for _scheduled_ auctions, they are still allowed
  # for draft auctions as the values for fuels and quantities may not be known.
  defp vessel_fuels_from_params(%{"vessels" => vessels, "fuels" => fuels})
       when is_list(vessels) and is_list(fuels) do
    Enum.map(fuels, fn fuel_id ->
      Enum.flat_map(vessels, fn vessel_id ->
        %{"vessel_id" => vessel_id, "fuel_id" => fuel_id}
      end)
    end)
  end

  defp vessel_fuels_from_params(%{"vessels" => vessels}) when is_list(vessels) do
    Enum.map(vessels, fn vessel_id ->
      %{"vessel_id" => vessel_id}
    end)
  end

  defp vessel_fuels_from_params(%{"fuels" => fuels}) when is_list(fuels) do
    Enum.map(fuels, fn fuel_id ->
      %{"fuel_id" => fuel_id}
    end)
  end

  defp vessel_fuels_from_params(_), do: []
end
