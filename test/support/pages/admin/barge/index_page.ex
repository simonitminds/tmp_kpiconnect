defmodule Oceanconnect.Admin.Barge.IndexPage do
  use Oceanconnect.Page

  @page_path "/admin/barges"

  def visit do
    navigate_to(@page_path)
  end

  def is_current_path? do
    current_path() == @page_path
  end

  def has_barges?(barges) do
    barges
    |> Enum.all?(fn barge ->
      case search_element(:css, ".qa-admin-barge-#{barge.id}") do
        {:ok, _} -> true
        _ -> false
      end
    end)
  end

  def has_barge?(id) do
    case search_element(:css, ".qa-admin-barge-#{id}") do
      {:error, _} -> false
      _ -> true
    end
  end

  def has_barge_name?(name) do
    barge_name =
      find_element(:css, ".qa-admin-barge-name")
      |> inner_text

    barge_name =~ name
  end

  def deactivate_barge(barge) do
    find_element(:css, ".qa-admin-barge-#{barge.id}")
    |> find_within_element(:css, ".qa-admin-barge-deactivate")
    |> click
  end

  def activate_barge(barge) do
    find_element(:css, ".qa-admin-barge-#{barge.id}")
    |> find_within_element(:css, ".qa-admin-barge-activate")
    |> click
  end

  def is_barge_active?(barge) do
    find_element(:css, ".qa-admin-barge-#{barge.id}")
    |> search_within_element(:css, ".qa-admin-barge-deactivate")
  end

  def is_barge_inactive?(barge) do
    find_element(:css, ".qa-admin-barge-#{barge.id}")
    |> search_within_element(:css, ".qa-admin-barge-activate")
  end
end
