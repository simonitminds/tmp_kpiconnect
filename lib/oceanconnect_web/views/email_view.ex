defmodule OceanconnectWeb.EmailView do
  use OceanconnectWeb, :view

  def full_name(user), do: Oceanconnect.Accounts.get_user_name!(user)

  def vessel_name_list(vessels) do
    vessels
    |> Enum.map(& &1.name)
    |> Enum.join(", ")
  end

  def duration_minute_string(duration) do
    "#{trunc(duration / 60_000)} minutes"
  end

  def convert_date?(date_time = %{}) do
    time = "#{leftpad(date_time.hour)}:#{leftpad(date_time.minute)} GMT"
    date = "#{leftpad(date_time.day)} #{month_abbreviation(date_time.month)} #{date_time.year}"
    "#{date} #{time}"
  end

  def convert_date?(_), do: "—"

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

  defp leftpad(integer) do
    String.pad_leading(Integer.to_string(integer), 2, "0")
  end
end
