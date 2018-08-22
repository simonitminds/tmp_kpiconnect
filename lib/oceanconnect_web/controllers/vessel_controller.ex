defmodule OceanconnectWeb.VesselController do
  use OceanconnectWeb, :controller

  alias Oceanconnect.Auctions
  alias Oceanconnect.Auctions.Vessel

  def index(conn, _params) do
    vessels = Auctions.list_vessels()
    render(conn, "index.html", vessels: vessels)
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
        |> redirect(to: vessel_path(conn, :show, vessel))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    vessel = Auctions.get_vessel!(id)
    render(conn, "show.html", vessel: vessel)
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
        |> redirect(to: vessel_path(conn, :show, vessel))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", vessel: vessel, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    vessel = Auctions.get_vessel!(id)
    {:ok, _vessel} = Auctions.delete_vessel(vessel)

    conn
    |> put_flash(:info, "Vessel deleted successfully.")
    |> redirect(to: vessel_path(conn, :index))
  end
end
