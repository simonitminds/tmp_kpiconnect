defmodule OceanconnectWeb.Admin.BargeController do
  use OceanconnectWeb, :controller

  alias Oceanconnect.Auctions
  alias Oceanconnect.Auctions.Barge

  def index(conn, params) do
    page = Auctions.list_barges(params)
    render(conn, "index.html",
			barges: page.entries,
		  page_number: page.page_number,
		  page_size: page.page_size,
		  total_pages: page.total_pages,
		  total_entries: page.total_entries)
  end

  def new(conn, _params) do
		ports = Auctions.list_active_ports
    changeset = Auctions.change_barge(%Barge{})
    render(conn, "new.html", changeset: changeset, ports: ports)
  end

  def create(conn, %{"barge" => barge_params}) do
		ports = Auctions.list_active_ports
    case Auctions.create_barge(barge_params) do
      {:ok, _barge} ->
        conn
        |> put_flash(:info, "Barge created successfully.")
        |> redirect(to: admin_barge_path(conn, :index))
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset, ports: ports)
    end
  end

  def edit(conn, %{"id" => id}) do
		ports = Auctions.list_active_ports
    barge = Auctions.get_barge!(id)
    changeset = Auctions.change_barge(barge)
    render(conn, "edit.html", barge: barge, changeset: changeset, ports: ports)
  end

  def update(conn, %{"id" => id, "barge" => barge_params}) do
    barge = Auctions.get_barge!(id)
		ports = Auctions.list_active_ports
    case Auctions.update_barge(barge, barge_params) do
      {:ok, _barge} ->
        conn
        |> put_flash(:info, "Barge updated successfully.")
        |> redirect(to: admin_barge_path(conn, :index))
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", barge: barge, changeset: changeset, ports: ports)
    end
  end

  def delete(conn, %{"id" => id}) do
    barge = Auctions.get_barge!(id)
    {:ok, _barge} = Auctions.delete_barge(barge)

    conn
    |> put_flash(:info, "Barge deleted successfully.")
    |> redirect(to: admin_barge_path(conn, :index))
  end

	def deactivate(conn, %{"barge_id" => barge_id}) do
		barge = Auctions.get_active_barge!(barge_id)
		{:ok, _barge} = Auctions.deactivate_barge(barge)

		conn
		|> put_flash(:info, "Barge deactivated successfully.")
		|> redirect(to: admin_barge_path(conn, :index))
	end

	def activate(conn, %{"barge_id" => barge_id}) do
		barge = Auctions.get_barge!(barge_id)
		{:ok, _barge} = Auctions.activate_barge(barge)

		conn
		|> put_flash(:info, "Barge activated successfully.")
		|> redirect(to: admin_barge_path(conn, :index))
	end
end
