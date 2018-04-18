defmodule OceanconnectWeb.AuctionView do
  use OceanconnectWeb, :view

  def auction_log_events(events) do
    Enum.map(events, fn(event) ->
      updated_data = event.data |> convert_dates
      event
      |> Map.put(:data, updated_data |> Poison.encode!)
      |> Map.put(:time, event.time_entered |> convert_date?)
    end)
  end

  def auction_log_supplier(%{state: %{winning_bid: %{supplier: supplier}}}) do
    supplier
  end
  def auction_log_supplier(%{state: %{winning_bid: nil}}), do: ""

  defp convert_dates(data = %{}) do
    Enum.reduce(enumerate_data(data), %{}, fn({k, v}, acc) ->
      Map.put(acc, k, convert_date?(v))
    end)
  end
  defp convert_dates(list = []) do
    Enum.map(list, fn(data) ->
      convert_dates(data)
    end)
  end

  defp enumerate_data(data = %{__struct__: _}) do
    Map.from_struct(data)
  end
  defp enumerate_data(data), do: data

  defp convert_date?(date_time = %DateTime{}) do
    "#{leftpad(date_time.day)}/#{leftpad(date_time.month)}/#{date_time.year} #{leftpad(date_time.hour)}:#{leftpad(date_time.minute)}"
  end
  defp convert_date?(date_time = %NaiveDateTime{}) do
    "#{leftpad(date_time.day)}/#{leftpad(date_time.month)}/#{date_time.year} #{leftpad(date_time.hour)}:#{leftpad(date_time.minute)}"
  end
  defp convert_date?(data = %{}), do: convert_dates(data)
  defp convert_date?(list = []), do: convert_dates(list)
  defp convert_date?(value), do: value

  defp leftpad(integer) do
    String.pad_leading(Integer.to_string(integer), 2, "0")
  end
end
