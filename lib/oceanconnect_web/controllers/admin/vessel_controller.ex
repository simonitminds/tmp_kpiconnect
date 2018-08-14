defmodule OceanconnectWeb.Admin.VesselController do
  use OceanconnectWeb, :controller

	alias Oceanconnect.Accounts
  alias Oceanconnect.Auctions
  alias Oceanconnect.Auctions.Vessel

  def index(conn, params) do
    page = Auctions.list_vessels(params)
    render(conn, "index.html",
			vessels: page.entries,
		  page_number: page.page_number,
		  page_size: page.page_size,
		  total_pages: page.total_pages,
		  total_entries: page.total_entries)
  end

  def new(conn, _params) do
		companies = Accounts.list_active_companies
    changeset = Auctions.change_vessel(%Vessel{})
    render(conn, "new.html", changeset: changeset, companies: companies)
  end

  def create(conn, %{"vessel" => vessel_params}) do
		companies = Accounts.list_active_companies
    case Auctions.create_vessel(vessel_params) do
      {:ok, _vessel} ->
        conn
        |> put_flash(:info, "Vessel created successfully.")
        |> redirect(to: admin_vessel_path(conn, :index))
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset, companies: companies)
    end
  end

  def edit(conn, %{"id" => id}) do
		companies = Accounts.list_active_companies
    vessel = Auctions.get_vessel!(id)
    changeset = Auctions.change_vessel(vessel)
    render(conn, "edit.html", vessel: vessel, changeset: changeset, companies: companies)
  end

  def update(conn, %{"id" => id, "vessel" => vessel_params}) do
    vessel = Auctions.get_vessel!(id)
		companies = Accounts.list_active_companies
    case Auctions.update_vessel(vessel, vessel_params) do
      {:ok, _vessel} ->
        conn
        |> put_flash(:info, "Vessel updated successfully.")
        |> redirect(to: admin_vessel_path(conn, :index))
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", vessel: vessel, changeset: changeset, companies: companies)
    end
  end

  def delete(conn, %{"id" => id}) do
    vessel = Auctions.get_vessel!(id)
    {:ok, _vessel} = Auctions.delete_vessel(vessel)

    conn
    |> put_flash(:info, "Vessel deleted successfully.")
    |> redirect(to: admin_vessel_path(conn, :index))
  end

  def deactivate(conn, %{"vessel_id" => vessel_id}) do
    vessel = Auctions.get_active_vessel!(vessel_id)
    {:ok, _vessel} = Auctions.deactivate_vessel(vessel)

    conn
    |> put_flash(:info, "Vessel deactivated successfully.")
    |> redirect(to: admin_vessel_path(conn, :index))
  end

  def activate(conn, %{"vessel_id" => vessel_id}) do
    vessel = Auctions.get_vessel!(vessel_id)
    {:ok, _vessel} = Auctions.activate_vessel(vessel)

    conn
    |> put_flash(:info, "Vessel activated successfully.")
    |> redirect(to: admin_vessel_path(conn, :index))
  end
end
