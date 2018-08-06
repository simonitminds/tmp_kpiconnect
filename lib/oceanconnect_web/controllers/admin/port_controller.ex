defmodule OceanconnectWeb.Admin.PortController do
  use OceanconnectWeb, :controller

  alias Oceanconnect.Auctions
  alias Oceanconnect.Auctions.Port

  def index(conn, params) do
    page = Auctions.list_ports(params)
    render(conn, "index.html",
			ports: page.entries,
		  page_number: page.page_number,
		  page_size: page.page_size,
		  total_pages: page.total_pages,
		  total_entries: page.total_entries)
  end

  def new(conn, _params) do
    changeset = Auctions.change_port(%Port{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"port" => port_params}) do
    case Auctions.create_port(port_params) do
      {:ok, port} ->
        conn
        |> put_flash(:info, "Port created successfully.")
        |> redirect(to: admin_port_path(conn, :show, port))
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    port = Auctions.get_port!(id)
    render(conn, "show.html", port: port)
  end

  def edit(conn, %{"id" => id}) do
    port = Auctions.get_port!(id)
    changeset = Auctions.change_port(port)
    render(conn, "edit.html", port: port, changeset: changeset)
  end

  def update(conn, %{"id" => id, "port" => port_params}) do
    port = Auctions.get_port!(id)

    case Auctions.update_port(port, port_params) do
      {:ok, port} ->
        conn
        |> put_flash(:info, "Port updated successfully.")
        |> redirect(to: admin_port_path(conn, :show, port))
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", port: port, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    port = Auctions.get_port!(id)
    {:ok, _port} = Auctions.delete_port(port)

    conn
    |> put_flash(:info, "Port deleted successfully.")
    |> redirect(to: admin_port_path(conn, :index))
  end
end
