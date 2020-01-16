defmodule OceanconnectWeb.EmailView do
  use OceanconnectWeb, :view
  import Oceanconnect.Auctions.Guards

  alias Oceanconnect.Auctions
  alias Oceanconnect.Accounts

  def full_name(user), do: Oceanconnect.Accounts.get_user_name!(user)

  def vessel_name_list(vessels) do
    vessels
    |> Enum.map(& &1.name)
    |> Enum.join(", ")
  end

  def auction_type(%{type: type}) do
    case type do
      "formula_related" -> "Formula-Related"
      "forward_fixed" -> "Forward-Fixed"
      "spot" -> "Spot"
    end
  end

  def auction_log_vessel_etas(%{auction_vessel_fuels: vessel_fuels}) do
    Enum.map(vessel_fuels, fn vessel_fuel ->
      {vessel_fuel.vessel, vessel_fuel.eta, vessel_fuel.etd}
    end)
  end

  def auction_log_vessel_etas(_auction), do: []

  def duration_minute_string(duration) do
    "#{trunc(duration / 60_000)} minutes"
  end

  def convert_date?(datetime, default \\ "—")

  def convert_date?(date_time = %{}, _default) do
    time = "#{leftpad(date_time.hour)}:#{leftpad(date_time.minute)} GMT"
    date = "#{leftpad(date_time.day)} #{month_abbreviation(date_time.month)} #{date_time.year}"
    "#{date} #{time}"
  end

  def convert_date?(_, default), do: default

  def month_abbreviation(month) when month >= 1 and month <= 12 do
    Enum.at(
      ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"],
      month - 1
    )
  end

  def format_price(amounts) when is_list(amounts) do
    Enum.map(amounts, &format_price/1)
    |> Enum.join(", ")
  end

  def format_price(amount) do
    case amount do
      amount when is_float(amount) ->
        amount = :erlang.float_to_binary(amount, decimals: 2)
        "$#{amount}"

      %Decimal{} = amount ->
        amount =
          amount
          |> Decimal.to_float()
          |> :erlang.float_to_binary(decimals: 2)

        "$#{amount}"

      _ ->
        amount
    end
  end

  def price_for_vessel_fuel(winning_solution_bids, vessel_fuel_id) do
    case winning_solution_bids[vessel_fuel_id] do
      nil -> nil
      _ -> Enum.map(winning_solution_bids[vessel_fuel_id], & &1.amount)
    end
  end

  def partial_name_for_type(%struct{type: type}, partial_type) when is_auction(struct) do
    "_#{type}_#{partial_type}.html"

    case type in ["forward_fixed", "formula_related"] do
      true -> "_term_#{partial_type}.html"
      _ -> "_spot_#{partial_type}.html"
    end
  end

  def term_length(%{fuel_quantity: monthly_fuel_volume, total_fuel_volume: total_fuel_volume})
      when is_nil(monthly_fuel_volume) or is_nil(total_fuel_volume) do
    "—"
  end

  def term_length(%{fuel_quantity: monthly_fuel_volume, total_fuel_volume: total_fuel_volume}) do
    months = floor(total_fuel_volume / monthly_fuel_volume)
    "#{months} months"
  end

  def format_month(%{month: month, year: year}) do
    month =
      [
        "January",
        "Febuary",
        "March",
        "April",
        "May",
        "June",
        "July",
        "August",
        "September",
        "October",
        "November",
        "December"
      ]
      |> Enum.at(month - 1)

    "#{month} #{year}"
  end

  def render_fixture_changes(fixture, changes, assigns) do
    Enum.map(changes, fn {key, value} ->
      {key, value, old_value} = changed_fixture_value_for_key(key, value, fixture)
      key = format_changed_field_name(key)
      render_change_partial(key, value, old_value, assigns)
    end)
  end

  defp changed_fixture_value_for_key(:vessel_id, new_vessel_id, %{vessel_id: old_vessel_id}) do
    %{name: old_vessel_name} = Auctions.get_vessel!(old_vessel_id)
    %{name: vessel_name} = Auctions.get_vessel!(new_vessel_id)
    {:vessel_id, vessel_name, old_vessel_name}
  end

  defp changed_fixture_value_for_key(:supplier_id, new_supplier_id, %{
         supplier_id: old_supplier_id
       }) do
    %{name: old_supplier_name} = Accounts.get_company!(old_supplier_id)
    %{name: supplier_name} = Accounts.get_company!(new_supplier_id)
    {:supplier_id, supplier_name, old_supplier_name}
  end

  defp changed_fixture_value_for_key(:supplier_id, new_supplier_id, _fixture) do
    %{name: supplier_name} = Accounts.get_company!(new_supplier_id)
    {:supplier_id, supplier_name, "PRIVATE INFORMATION"}
  end

  defp changed_fixture_value_for_key(:fuel_id, new_fuel_id, %{fuel_id: old_fuel_id}) do
    %{name: old_fuel_name} = Auctions.get_fuel!(old_fuel_id)
    %{name: fuel_name} = Auctions.get_fuel!(new_fuel_id)
    {:fuel_id, fuel_name, old_fuel_name}
  end

  defp changed_fixture_value_for_key(key, value, fixture) when key != :comment do
    fixture = Map.from_struct(fixture)
    {key, value, fixture[key]}
  end

  defp changed_fixture_value_for_key(_, _, _), do: nil

  defp format_changed_field_name(key) do
    cond do
      key in [:eta, :etd] ->
        Atom.to_string(key)
        |> String.split("_")
        |> hd()
        |> String.upcase()

      true ->
        Atom.to_string(key)
        |> String.split("_")
        |> hd()
        |> String.capitalize()
    end
  end

  defp render_change_partial(key, value, previous_value, assigns) do
    partial_type =
      key
      |> String.downcase()
      |> get_partial_type_for_key()

    render(
      partial_type,
      Map.merge(assigns, %{
        changed_field: key,
        value: value,
        previous_value: previous_value
      })
    )
  end

  defp get_partial_type_for_key(key) when key in ["eta", "etd"], do: "_fixture_change_date.html"
  defp get_partial_type_for_key("price"), do: "_fixture_change_price.html"
  defp get_partial_type_for_key("quantity"), do: "_fixture_change_quantity.html"
  defp get_partial_type_for_key(_), do: "_fixture_change.html"

  def render_delivered_fixture_values(fixture) do
    fixture = Map.from_struct(fixture)

    keys =
      fixture
      |> Map.keys()
      |> Enum.reject(fn key ->
        key =
          key
          |> Atom.to_string()

        String.starts_with?(key, "original") or
          String.starts_with?(key, "delivered") or
          String.ends_with?(key, "id")
      end)

    delivered_fixture =
      Enum.reduce(keys, %{}, fn key, acc ->
        delivered_key = String.to_atom("delivered_#{key}")

        value =
          cond do
            key in [:vessel, :fuel, :supplier] ->
              cond do
                fixture[key].id == fixture[delivered_key].id -> fixture[key]
                true -> fixture[delivered_key]
              end

            true ->
              cond do
                fixture[key] == fixture[delivered_key] -> fixture[key]
                true -> fixture[delivered_key]
              end
          end

        Map.put(acc, key, value)
      end)

    render_delivered_fixture_partial(delivered_fixture)
  end

  defp render_delivered_fixture_partial(fixture) do
    render("_delivered_fixture.html",
      fixture: fixture
    )
  end

  defp leftpad(integer) do
    String.pad_leading(Integer.to_string(integer), 2, "0")
  end
end
