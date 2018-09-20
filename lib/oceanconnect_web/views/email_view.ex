defmodule OceanconnectWeb.EmailView do
  use OceanconnectWeb, :view

  def full_name(user) do
    "#{user.first_name} #{user.last_name}"
  end

  def duration_minute_string(duration) do
    "#{trunc(duration / 60_000)} minutes"
  end

  def convert_date?(date_time = %{}) do
    time = "#{leftpad(date_time.hour)}:#{leftpad(date_time.minute)} GMT"
    date = "#{leftpad(date_time.day)} #{month_abbreviation(date_time.month)} #{date_time.year}"
    "#{date} #{time}"
  end

  def month_abbreviation(month) when month >= 1 and month <= 12 do
    Enum.at(
      ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"],
      month - 1
    )
  end

  def convert_date?(_), do: "—"

  def format_price(amount) do
    amount = :erlang.float_to_binary(amount, decimals: 2)
    "$#{amount}"
  end

  defp leftpad(integer) do
    String.pad_leading(Integer.to_string(integer), 2, "0")
  end
end
