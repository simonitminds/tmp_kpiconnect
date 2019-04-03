defmodule OceanconnectWeb.AuctionController do
  use OceanconnectWeb, :controller

  import Oceanconnect.Auctions.Guards

  alias Oceanconnect.{Auctions, Messages}

  alias Oceanconnect.Auctions.{
    Auction,
    TermAuction,
    AuctionEventStore,
    AuctionPayload,
    Payloads
  }

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

    with %struct{} when is_auction(struct) <- auction,
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
    admin? = Auth.current_user_is_admin?(conn)

    if admin? do
      admin = Auth.current_admin(conn)

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

    changeset =
      Auctions.change_auction(%Auction{})
      |> Map.put(:action, :create)

    [fuels, fuel_indexes, ports, vessels] = auction_inputs_by_buyer(conn)

    render(
      conn,
      "new.html",
      changeset: changeset,
      auction: %Auction{},
      fuels: fuels,
      fuel_indexes: fuel_indexes,
      ports: ports,
      vessels: vessels,
      suppliers: Poison.encode!([]),
      credit_margin_amount: credit_margin_amount
    )
  end

  def create(conn, %{"auction" => auction_params}) do
    user = Auth.current_user(conn)
    credit_margin_amount = user.company.credit_margin_amount

    updated_params =
      auction_params
      |> Map.put("buyer_id", user.company.id)
      |> normalize_auction_params()

    case Auctions.create_auction(updated_params, user) do
      {:ok, auction} ->
        conn
        |> put_flash(:info, "Auction created successfully.")
        |> redirect(to: auction_path(conn, :show, auction))

      {:error, %Ecto.Changeset{} = changeset} ->
        [auction, json_auction, suppliers] = build_payload_from_changeset(changeset)
        [fuels, fuel_indexes, ports, vessels] = auction_inputs_by_buyer(conn)

        render(
          conn,
          "new.html",
          changeset: changeset,
          auction: auction,
          json_auction: json_auction,
          fuels: fuels,
          fuel_indexes: fuel_indexes,
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
    is_admin = OceanconnectWeb.Plugs.Auth.current_user_is_admin?(conn)

    if Auctions.is_participant?(auction, Auth.current_user(conn).company_id) || is_admin do
      render(conn, "show.html", auction: auction, credit_margin_amount: credit_margin_amount)
    else
      redirect(conn, to: auction_path(conn, :index))
    end
  end

  def edit(conn, %{"id" => id}) do
    with auction = %struct{} when is_auction(struct) <-
           id |> Auctions.get_auction() |> Auctions.fully_loaded(),
         true <- auction.buyer_id == Auth.current_user(conn).company_id,
         false <- Auctions.get_auction_state!(auction).status in [:open, :decision] do
      changeset =
        Auctions.change_auction(auction)
        |> Map.put(:action, :update)

      [auction, json_auction, suppliers] = build_payload_from_changeset(changeset)
      [fuels, fuel_indexes, ports, vessels] = auction_inputs_by_buyer(conn)

      user = Auth.current_user(conn)
      credit_margin_amount = user.company.credit_margin_amount

      render(
        conn,
        "edit.html",
        changeset: changeset,
        auction: auction,
        json_auction: json_auction,
        fuels: fuels,
        fuel_indexes: fuel_indexes,
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
    user = Auth.current_user(conn)
    credit_margin_amount = user.company.credit_margin_amount

    with auction = %struct{} when is_auction(struct) <-
           id |> Auctions.get_auction() |> Auctions.fully_loaded(),
         true <- auction.buyer_id == user.company_id,
         false <- Auctions.get_auction_state!(auction).status in [:open, :decision] do

      updated_params =
        auction_params
        |> normalize_auction_params()

      case Auctions.update_auction(auction, updated_params, user) do
        {:ok, auction} ->
          conn
          |> put_flash(:info, "Auction updated successfully.")
          |> redirect(to: auction_path(conn, :show, auction))

        {:error, %Ecto.Changeset{} = changeset} ->
          [auction, json_auction, suppliers] = build_payload_from_changeset(changeset)
          [fuels, fuel_indexes, ports, vessels] = auction_inputs_by_buyer(conn)

          render(
            conn,
            "edit.html",
            changeset: changeset,
            auction: auction,
            json_auction: json_auction,
            fuels: fuels,
            fuel_indexes: fuel_indexes,
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

  defp normalize_auction_params(params = %{"type" => type})
       when type in ["forward_fixed", "formula_related"] do
    params
    |> TermAuction.from_params()
  end

  defp normalize_auction_params(params) do
    auction_vessel_fuels = vessel_fuels_from_params(params)

    params
    |> Auction.from_params()
    |> Map.put("auction_vessel_fuels", auction_vessel_fuels)
  end

  defp auction_inputs_by_buyer(conn) do
    buyer = Auth.current_user(conn)
    buyer_company = buyer.company
    fuels = Auctions.list_fuels()

    fuel_indexes =
      Auctions.list_fuel_index_entries()
      |> Auctions.fully_loaded_index()

    ports = Auctions.ports_for_company(buyer_company)
    vessels = Auctions.vessels_for_buyer(buyer_company)

    Enum.map([fuels, fuel_indexes, ports, vessels], fn list ->
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
          Poison.encode!([])

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

  defp vessel_fuels_from_params(%{
         "auction_vessel_fuels" => auction_vessel_fuels,
         "vessels" => vessels
       })
       when is_map(auction_vessel_fuels) do
    Enum.flat_map(auction_vessel_fuels, fn {fuel_id, vessel_quantities} ->
      Enum.map(vessel_quantities, fn {vessel_id, quantity} ->
        vessel_data = Map.get(vessels, vessel_id)

        %{
          "fuel_id" => fuel_id,
          "vessel_id" => vessel_id,
          "quantity" => quantity,
          "eta" => vessel_data["eta"],
          "etd" => vessel_data["etd"]
        }
      end)
    end)
    |> Enum.reject(fn vf -> vf["quantity"] == "0" end)
  end

  # For draft auctions, there might only be vessels or fuels provided. Even
  # though these are invalid for _scheduled_ auctions, they are still allowed
  # for draft auctions as the values for fuels and quantities may not be known.
  defp vessel_fuels_from_params(%{"vessels" => vessels, "fuels" => fuels})
       when is_map(vessels) and is_list(fuels) do
    Enum.map(fuels, fn fuel_id ->
      Enum.flat_map(vessels, fn {vessel_id, vessel_data} ->
        %{
          "vessel_id" => vessel_id,
          "fuel_id" => fuel_id,
          "eta" => vessel_data["eta"],
          "etd" => vessel_data["etd"]
        }
      end)
    end)
  end

  defp vessel_fuels_from_params(%{"vessels" => vessels}) when is_map(vessels) do
    Enum.map(vessels, fn {vessel_id, vessel_data} ->
      %{"vessel_id" => vessel_id, "eta" => vessel_data["eta"], "etd" => vessel_data["etd"]}
    end)
  end

  defp vessel_fuels_from_params(%{"fuels" => fuels}) when is_list(fuels) do
    Enum.map(fuels, fn fuel_id ->
      %{"fuel_id" => fuel_id}
    end)
  end

  defp vessel_fuels_from_params(_), do: []
end
