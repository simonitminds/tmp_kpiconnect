defmodule OceanconnectWeb.Admin.FuelController do
  use OceanconnectWeb, :controller

  alias Oceanconnect.Auctions
  alias Oceanconnect.Auctions.Fuel

  def index(conn, params) do
    page = Auctions.list_fuels(params)
    render(conn, "index.html",
			fuels: page.entries,
		  page_number: page.page_number,
		  page_size: page.page_size,
		  total_pages: page.total_pages,
		  total_entries: page.total_entries)
  end

  def new(conn, _params) do
    changeset = Auctions.change_fuel(%Fuel{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"fuel" => fuel_params}) do
    case Auctions.create_fuel(fuel_params) do
      {:ok, fuel} ->
        conn
        |> put_flash(:info, "Fuel created successfully.")
        |> redirect(to: admin_fuel_path(conn, :index))
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    fuel = Auctions.get_fuel!(id)
    render(conn, "show.html", fuel: fuel)
  end

  def edit(conn, %{"id" => id}) do
    fuel = Auctions.get_fuel!(id)
    changeset = Auctions.change_fuel(fuel)
    render(conn, "edit.html", fuel: fuel, changeset: changeset)
  end

  def update(conn, %{"id" => id, "fuel" => fuel_params}) do
    fuel = Auctions.get_fuel!(id)

    case Auctions.update_fuel(fuel, fuel_params) do
      {:ok, fuel} ->
        conn
        |> put_flash(:info, "Fuel updated successfully.")
        |> redirect(to: admin_fuel_path(conn, :index))
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", fuel: fuel, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    fuel = Auctions.get_fuel!(id)
    {:ok, _fuel} = Auctions.delete_fuel(fuel)

    conn
    |> put_flash(:info, "Fuel deleted successfully.")
    |> redirect(to: admin_fuel_path(conn, :index))
  end
end
