defmodule OceanconnectWeb.Admin.FuelIndexController do
  use OceanconnectWeb, :controller

  alias Oceanconnect.Auctions
  alias Oceanconnect.Auctions.FuelIndex

  def index(conn, _) do
    page = Auctions.list_fuel_index_entries()
    render(conn,
      "index.html",
      fuel_index_entries: page.entries,
      page_number: page.page_number,
      page_size: page.page_size,
      total_pages: page.total_pages,
      total_entries: page.total_entries
    )
  end

  def new(conn, _) do
    fuels = Auctions.list_active_fuels()
    ports = Auctions.list_active_ports()
    changeset = Auctions.change_fuel_index(%FuelIndex{})
    render(conn, "new.html", changeset: changeset, fuels: fuels, ports: ports)
  end

  def create(conn, %{"fuel_index" => fuel_index_params}) do
    fuels = Auctions.list_active_fuels()
    ports = Auctions.list_active_ports()

    case Auctions.create_fuel_index(fuel_index_params) do
      {:ok, fuel_index} ->
        conn
        |> put_flash(:info, "Fuel index created successfully.")
        |> put_status(302)
        |> redirect(to: admin_fuel_index_path(conn, :index))
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset, fuels: fuels, ports: ports)
    end
  end

  def edit(conn, %{"id" => id}) do
    fuels = Auctions.list_active_fuels()
    ports = Auctions.list_active_ports()
    fuel_index = Auctions.get_fuel_index!(id)
    changeset = Auctions.change_fuel_index(fuel_index)
    render(conn, "edit.html", fuel_index: fuel_index, changeset: changeset, fuels: fuels, ports: ports)
  end

  def update(conn, %{"id" => id, "fuel_index" => fuel_index_params}) do
    fuels = Auctions.list_active_fuels()
    ports = Auctions.list_active_ports()
    fuel_index = Auctions.get_fuel_index!(id)

    case Auctions.update_fuel_index(fuel_index, fuel_index_params) do
      {:ok, fuel_index} ->
        conn
        |> put_flash(:info, "Fuel index updated successfully.")
        |> redirect(to: admin_fuel_index_path(conn, :index))
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", fuel_index: fuel_index, changeset: changeset, fuels: fuels, ports: ports)
    end
  end

  def delete(conn, %{"id" => id}) do
    fuel_index = Auctions.get_fuel_index!(id)
    {:ok, _fuel_index} = Auctions.delete_fuel_index(fuel_index)

    conn
    |> put_flash(:info, "Fuel index deleted successfully.")
    |> redirect(to: admin_fuel_index_path(conn, :index))
  end

  def deactivate(conn, %{"fuel_index_id" => fuel_index_id}) do
    fuel = Auctions.get_active_fuel_index!(fuel_index_id)
    {:ok, _fuel} = Auctions.deactivate_fuel_index(fuel)

    conn
    |> put_flash(:info, "Fuel deactivated successfully.")
    |> redirect(to: admin_fuel_index_path(conn, :index))
  end

  def activate(conn, %{"fuel_index_id" => fuel_index_id}) do
    fuel = Auctions.get_fuel_index!(fuel_index_id)
    {:ok, _fuel} = Auctions.activate_fuel_index(fuel)

    conn
    |> put_flash(:info, "Fuel activated successfully.")
    |> redirect(to: admin_fuel_index_path(conn, :index))
  end
end
