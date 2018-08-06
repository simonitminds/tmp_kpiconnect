defmodule OceanconnectWeb.Admin.CompanyController do
  use OceanconnectWeb, :controller

  alias Oceanconnect.Accounts
  alias Oceanconnect.Accounts.Company

  def index(conn, params) do
    page = Accounts.list_companies(params)
    render(conn, "index.html",
			companies: page.entries,
		  page_number: page.page_number,
		  page_size: page.page_size,
		  total_pages: page.total_pages,
		  total_entries: page.total_entries)
  end

  def new(conn, _params) do
    changeset = Accounts.change_company(%Company{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"company" => company_params}) do
    case Accounts.create_company(company_params) do
      {:ok, company} ->
        conn
        |> put_flash(:info, "Company created successfully.")
        |> redirect(to: admin_company_path(conn, :show, company))
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    company = Accounts.get_company!(id)
    render(conn, "show.html", company: company)
  end

  def edit(conn, %{"id" => id}) do
    company = Accounts.get_company!(id)
    changeset = Accounts.change_company(company)
    render(conn, "edit.html", company: company, changeset: changeset)
  end

  def update(conn, %{"id" => id, "company" => company_params}) do
    company = Accounts.get_company!(id)

    case Accounts.update_company(company, company_params) do
      {:ok, company} ->
        conn
        |> put_flash(:info, "Company updated successfully.")
        |> redirect(to: admin_company_path(conn, :show, company))
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", company: company, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    company = Accounts.get_company!(id)
    {:ok, _company} = Accounts.delete_company(company)

    conn
    |> put_flash(:info, "Company deleted successfully.")
    |> redirect(to: admin_company_path(conn, :index))
  end
end
