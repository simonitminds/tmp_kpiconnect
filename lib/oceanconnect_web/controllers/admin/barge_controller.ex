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
    changeset = Auctions.change_barge(%Barge{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"barge" => barge_params}) do
    case Auctions.create_barge(barge_params) do
      {:ok, barge} ->
        conn
        |> put_flash(:info, "Barge created successfully.")
        |> redirect(to: admin_barge_path(conn, :show, barge))
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    barge = Auctions.get_barge!(id)
    render(conn, "show.html", barge: barge)
  end

  def edit(conn, %{"id" => id}) do
    barge = Auctions.get_barge!(id)
    changeset = Auctions.change_barge(barge)
    render(conn, "edit.html", barge: barge, changeset: changeset)
  end

  def update(conn, %{"id" => id, "barge" => barge_params}) do
    barge = Auctions.get_barge!(id)

    case Auctions.update_barge(barge, barge_params) do
      {:ok, barge} ->
        conn
        |> put_flash(:info, "Barge updated successfully.")
        |> redirect(to: admin_barge_path(conn, :show, barge))
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", barge: barge, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    barge = Auctions.get_barge!(id)
    {:ok, _barge} = Auctions.delete_barge(barge)

    conn
    |> put_flash(:info, "Barge deleted successfully.")
    |> redirect(to: admin_barge_path(conn, :index))
  end
end
