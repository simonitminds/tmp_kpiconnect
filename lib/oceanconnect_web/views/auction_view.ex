defmodule OceanconnectWeb.AuctionView do
  use OceanconnectWeb, :view

  def auction_log_events(events) do
    Enum.map(events, fn(event) ->
      event
      |> Map.put(:data, event.data |> Poison.encode!)
      |> Map.put(:time, event.time_entered |> convert_date?)
    end)
  end

  def auction_log_supplier(%{state: %{winning_bid: %{supplier: supplier}}}) do
    supplier
  end
  def auction_log_supplier(%{state: %{winning_bid: nil}}), do: "—"

  def auction_log_winning_bid(%{state: %{winning_bid: %{amount: amount}}}) do
    :erlang.float_to_binary(amount, [decimals: 2])
  end
  def auction_log_winning_bid(%{state: %{winning_bid: nil}}), do: "—"

  defp convert_date?(date_time = %{}) do
    time = "#{leftpad(date_time.hour)}:#{leftpad(date_time.minute)}:#{leftpad(date_time.second)}"
    date = "#{leftpad(date_time.day)}/#{leftpad(date_time.month)}/#{date_time.year}"
    "#{date} #{time}"
  end

  defp leftpad(integer) do
    String.pad_leading(Integer.to_string(integer), 2, "0")
  end
end
