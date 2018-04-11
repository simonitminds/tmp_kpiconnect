defmodule Oceanconnect.Utilities do

  def round_time_remaining(time_remaining) do
    round(Float.round((time_remaining / 1_000), 0) * 1_000)
  end

  def maybe_convert_date_times(auction = %{}) do
    Enum.reduce(auction, %{}, fn({k, v}, acc) ->
      value = case k in ["auction_start", "eta", "etd"] do
        true -> convert_date_time(v)
        false -> v
      end
      Map.put(acc, k, value)
    end)
  end
  def maybe_convert_date_times(input), do: input

  def convert_date_time(date_time = %{}) do
    DateTime.utc_now()
    |> Map.merge(date_time)
    |> DateTime.to_unix
    |> Integer.to_string
  end
  def convert_date_time(epoch) do
    DateTime.from_unix!(String.to_integer(epoch))
  end

end
