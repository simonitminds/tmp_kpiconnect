defmodule Oceanconnect.Utilities do

  def reduced_payload(auction_payload = %{time_remaining: time_remaining}) do
    reduced_payload = Map.drop(auction_payload, [:__struct__, :auction, :current_server_time])

    %{reduced_payload | time_remaining: round_time_remaining(time_remaining)}
  end

  def round_time_remaining(time_remaining) do
    round(Float.round((time_remaining / 10_000), 0) * 10_000)
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
