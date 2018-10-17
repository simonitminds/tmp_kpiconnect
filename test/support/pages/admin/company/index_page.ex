defmodule Oceanconnect.Admin.Company.IndexPage do
  use Oceanconnect.Page

  @page_path "/admin/companies"

  def visit do
    navigate_to(@page_path)
  end

  def is_current_path? do
    current_path() == @page_path
  end

  def has_companies?(companies) do
    companies
    |> Enum.all?(fn company ->
      case search_element(:css, ".qa-admin-company-#{company.id}") do
        {:ok, _} -> true
        _ -> false
      end
    end)
  end

  def has_company?(id) do
    case search_element(:css, ".qa-admin-company-#{id}") do
      {:error, _} -> false
      _ -> true
    end
  end

  def has_company_name?(name, id) do
    company_name =
      find_element(:css, ".qa-admin-company-#{id}")
      |> find_within_element(:css, ".qa-admin-company-name")
      |> inner_text

    company_name =~ name
  end

  def company_created_successfully? do
    page_text = visible_page_text()
    page_text =~ "Company created successfully."
  end

  def deactivate_company(company) do
    find_element(:css, ".qa-admin-company-#{company.id}")
    |> find_within_element(:css, ".qa-admin-company-deactivate")
    |> click
  end

  def activate_company(company) do
    find_element(:css, ".qa-admin-company-#{company.id}")
    |> find_within_element(:css, ".qa-admin-company-activate")
    |> click
  end

  def is_company_active?(company) do
    find_element(:css, ".qa-admin-company-#{company.id}")
    |> search_within_element(:css, ".qa-admin-company-deactivate")
  end

  def is_company_inactive?(company) do
    find_element(:css, ".qa-admin-company-#{company.id}")
    |> search_within_element(:css, ".qa-admin-company-activate")
  end
end
