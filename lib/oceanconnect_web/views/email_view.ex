defmodule OceanconnectWeb.EmailView do
  use OceanconnectWeb, :view
  import Oceanconnect.Auctions.Guards

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

  def auction_log_vessel_etas(%{auction_vessel_fuels: vessel_fuels, vessels: vessels}) do
    Enum.map(vessels, fn vessel ->
      eta =
        vessel_fuels
        |> Enum.map(fn vessel_fuel -> vessel_fuel.eta end)
        |> Enum.filter(& &1)
        |> Enum.min_by(&DateTime.to_unix/1, fn -> nil end)

      etd =
        vessel_fuels
        |> Enum.map(fn vessel_fuel -> vessel_fuel.etd end)
        |> Enum.filter(& &1)
        |> Enum.min_by(&DateTime.to_unix/1, fn -> nil end)

      {vessel, eta, etd}
    end)
  end

  def auction_log_vessel_etas(auction) do
    []
  end

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

  defp leftpad(integer) do
    String.pad_leading(Integer.to_string(integer), 2, "0")
  end
end
