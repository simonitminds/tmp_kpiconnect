defmodule OceanconnectWeb.Admin.PortController do
  use OceanconnectWeb, :controller

  alias Oceanconnect.Accounts
  alias Oceanconnect.Auctions
  alias Oceanconnect.Auctions.Port

  def index(conn, params) do
    page = Auctions.list_ports(params)

    render(
      conn,
      "index.html",
      ports: page.entries,
      page_number: page.page_number,
      page_size: page.page_size,
      total_pages: page.total_pages,
      total_entries: page.total_entries
    )
  end

  def new(conn, _params) do
    port = %Port{} |> Auctions.port_with_companies()
    companies = Accounts.list_active_companies()
    changeset = Auctions.change_port(%Port{})
    render(conn, "new.html", changeset: changeset, port: port, companies: companies)
  end

  def create(conn, %{"port" => port_params = %{"companies" => selected_companies}}) do
    port =
      %Port{}
      |> Auctions.port_with_companies()

    companies = Accounts.list_active_companies()

    selected_companies =
      selected_companies
      |> Enum.map(fn company ->
        {company_id, is_selected} = company

        if is_selected == "true" do
          company_id
        end
      end)
      |> Enum.filter(fn company_id -> company_id != nil end)
      |> Enum.map(& &1)

    port_params =
      port_params
      |> Map.put("companies", selected_companies)

    case Auctions.create_port(port_params) do
      {:ok, _port} ->
        conn
        |> put_flash(:info, "Port created successfully.")
        |> redirect(to: admin_port_path(conn, :index))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset, port: port, companies: companies)
    end
  end

  def create(conn, %{"port" => port_params}) do
    port = %Port{} |> Auctions.port_with_companies()
    companies = Accounts.list_active_companies()

    case Auctions.create_port(port_params) do
      {:ok, _port} ->
        conn
        |> put_flash(:info, "Port created successfully.")
        |> redirect(to: admin_port_path(conn, :index))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset, port: port, companies: companies)
    end
  end

  def edit(conn, %{"id" => id}) do
    companies = Accounts.list_active_companies()

    port =
      Auctions.get_port!(id)
      |> Auctions.port_with_companies()

    changeset = Auctions.change_port(port)
    render(conn, "edit.html", port: port, changeset: changeset, companies: companies)
  end

  def update(conn, %{"id" => id, "port" => port_params = %{"companies" => companies}}) do
    port = Auctions.get_port!(id) |> Auctions.port_with_companies()
    existing_companies = Accounts.list_active_companies()

    selected_companies = companies
    |> Enum.map(fn company ->
      {company_id, is_selected} = company

      if is_selected == "true" do
        company_id
      end
    end)
    |> Enum.filter(fn company_id -> company_id != nil end)
    |> Enum.map(& &1)

    removed_companies = companies
    |> Enum.map(fn company ->
      {company_id, is_selected} = company

      if is_selected == "false" do
        company_id
      end
    end)
    |> Enum.filter(fn company_id -> company_id != nil end)
    |> Enum.map(& &1)

    port_params =
      port_params
      |> Map.put("companies", selected_companies)
      |> Map.put("removed_companies", removed_companies)

    case Auctions.update_port(port, port_params) do
      {:ok, _port} ->
        conn
        |> put_flash(:info, "Port updated successfully.")
        |> redirect(to: admin_port_path(conn, :index))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", port: port, changeset: changeset, companies: existing_companies)
    end
  end

  def update(conn, %{"id" => id, "port" => port_params}) do
    port = Auctions.get_port!(id) |> Auctions.port_with_companies()
    companies = Accounts.list_active_companies()

    case Auctions.update_port(port, port_params) do
      {:ok, _port} ->
        conn
        |> put_flash(:info, "Port updated successfully.")
        |> redirect(to: admin_port_path(conn, :index))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", port: port, changeset: changeset, companies: companies)
    end
  end

  def delete(conn, %{"id" => id}) do
    port = Auctions.get_port!(id)
    {:ok, _port} = Auctions.delete_port(port)

    conn
    |> put_flash(:info, "Port deleted successfully.")
    |> redirect(to: admin_port_path(conn, :index))
  end

  def deactivate(conn, %{"port_id" => port_id}) do
    port = Auctions.get_active_port!(port_id)
    {:ok, _port} = Auctions.deactivate_port(port)

    conn
    |> put_flash(:info, "Port deactivated successfully.")
    |> redirect(to: admin_port_path(conn, :index))
  end

  def activate(conn, %{"port_id" => port_id}) do
    port = Auctions.get_port!(port_id)
    {:ok, _port} = Auctions.activate_port(port)

    conn
    |> put_flash(:info, "Port activated successfully.")
    |> redirect(to: admin_port_path(conn, :index))
  end
end
