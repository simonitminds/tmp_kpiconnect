defmodule OceanconnectWeb.Admin.VesselController do
  use OceanconnectWeb, :controller

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
    changeset = Auctions.change_vessel(%Vessel{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"vessel" => vessel_params}) do
    case Auctions.create_vessel(vessel_params) do
      {:ok, vessel} ->
        conn
        |> put_flash(:info, "Vessel created successfully.")
        |> redirect(to: admin_vessel_path(conn, :index))
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def edit(conn, %{"id" => id}) do
    vessel = Auctions.get_vessel!(id)
    changeset = Auctions.change_vessel(vessel)
    render(conn, "edit.html", vessel: vessel, changeset: changeset)
  end

  def update(conn, %{"id" => id, "vessel" => vessel_params}) do
    vessel = Auctions.get_vessel!(id)

    case Auctions.update_vessel(vessel, vessel_params) do
      {:ok, vessel} ->
        conn
        |> put_flash(:info, "Vessel updated successfully.")
        |> redirect(to: admin_vessel_path(conn, :index))
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", vessel: vessel, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    vessel = Auctions.get_vessel!(id)
    {:ok, _vessel} = Auctions.delete_vessel(vessel)

    conn
    |> put_flash(:info, "Vessel deleted successfully.")
    |> redirect(to: admin_vessel_path(conn, :index))
  end

  def deactivate(conn, %{"id" => id}) do
    vessel = Auctions.get_active_vessel!(id)
    {:ok, _vessel} = Auctions.deactivate_vessel(vessel)

    conn
    |> put_flash(:info, "Vessel deactivated successfully.")
    |> redirect(to: admin_vessel_path(conn, :index))
  end

end
