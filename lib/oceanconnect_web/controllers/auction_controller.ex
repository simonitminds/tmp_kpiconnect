defmodule OceanconnectWeb.AuctionController do
  use OceanconnectWeb, :controller
  alias Oceanconnect.Auctions
  alias Oceanconnect.Auctions.{Auction, AuctionEventStore}
  alias OceanconnectWeb.Plugs.Auth

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def log(conn, %{"id" => id}) do

    current_company_id = OceanconnectWeb.Plugs.Auth.current_user(conn).company_id
    auction = id
    |> Auctions.get_auction!
    |> Auctions.fully_loaded

    with %Auction{} <- auction,
      true <- current_company_id == auction.buyer_id,
      false <- Auctions.get_auction_state!(auction).status in [:pending, :open]
    do
      events = auction
      |> AuctionEventStore.event_list
      |> make_data_renderable

      render(conn, "log.html", auction: auction, events: events)
    else
      _ -> redirect(conn, to: auction_path(conn, :index))
    end
  end

  defp make_data_renderable(events) do
    Enum.map(events, fn(event) ->
      updated_data = event.data |> convert_dates
      event
      |> Map.put(:data, updated_data |> Poison.encode!)
      |> Map.put(:time, event.time_entered |> convert_date?)
    end)
  end

  defp convert_dates(data = %{}) do
    Enum.reduce(enumerate_data(data), %{}, fn({k, v}, acc) ->
      Map.put(acc, k, convert_date?(v))
    end)
  end
  defp convert_dates(list = []) do
    Enum.map(list, fn(data) ->
      convert_dates(data)
    end)
  end

  defp enumerate_data(data = %{__struct__: _}) do
    Map.from_struct(data)
  end
  defp enumerate_data(data), do: data

  defp convert_date?(date_time = %DateTime{}) do
    "#{leftpad(date_time.day)}/#{leftpad(date_time.month)}/#{date_time.year} #{leftpad(date_time.hour)}:#{leftpad(date_time.minute)}"
  end
  defp convert_date?(date_time = %NaiveDateTime{}) do
    "#{leftpad(date_time.day)}/#{leftpad(date_time.month)}/#{date_time.year} #{leftpad(date_time.hour)}:#{leftpad(date_time.minute)}"
  end
  defp convert_date?(data = %{}), do: convert_dates(data)
  defp convert_date?(list = []), do: convert_dates(list)
  defp convert_date?(value), do: value

  defp leftpad(integer) do
    String.pad_leading(Integer.to_string(integer), 2, "0")
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
          |> Auctions.supplier_list_for_auction(auction.buyer_id)
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
              |> Auctions.supplier_list_for_auction(auction.buyer_id)
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
