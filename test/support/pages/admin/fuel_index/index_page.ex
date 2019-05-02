defmodule Oceanconnect.Admin.FuelIndex.IndexPage do
  use Oceanconnect.Page

  @page_path "/admin/fuel_index_entries"

  def visit do
    navigate_to(@page_path)
  end

  def is_current_path? do
    current_path() == @page_path
  end

  def has_fuel_index_entries?(fuel_index_entries) do
    fuel_index_entries
    |> Enum.all?(fn fuel_index ->
      case search_element(:css, ".qa-admin-fuel_index-#{fuel_index.id}") do
        {:ok, _} -> true
        _ -> false
      end
    end)
  end

  def has_fuel_index?(id) do
    case search_element(:css, ".qa-admin-fuel_index-#{id}") do
      {:error, _} -> false
      _ -> true
    end
  end

  def has_fuel_index_name?(name) do
    fuel_name =
      find_element(:css, ".qa-admin-fuel_index-name")
      |> inner_text

    fuel_name =~ name
  end

  def deactivate_fuel_index(fuel_index) do
    find_element(:css, ".qa-admin-fuel_index-#{fuel_index.id}")
    |> find_within_element(:css, ".qa-admin-fuel_index-deactivate")
    |> click
  end

  def activate_fuel_index(fuel_index) do
    find_element(:css, ".qa-admin-fuel_index-#{fuel_index.id}")
    |> find_within_element(:css, ".qa-admin-fuel_index-activate")
    |> click
  end

  def is_fuel_index_active?(fuel_index) do
    find_element(:css, ".qa-admin-fuel_index-#{fuel_index.id}")
    |> search_within_element(:css, ".qa-admin-fuel_index-deactivate")
  end

  def is_fuel_index_inactive?(fuel_index) do
    find_element(:css, ".qa-admin-fuel_index-#{fuel_index.id}")
    |> search_within_element(:css, ".qa-admin-fuel_index-activate")
  end

  def next_page do
    click({:css, ".qa-next-page"})
  end

  def previous_page do
    click({:css, ".qa-prev-page"})
  end
end
