defmodule Oceanconnect.Utilities do

  def trunc_times(auction_state = %{time_remaining: time_remaining}) do
    reduced_state = Map.drop(auction_state, [:current_server_time])

    %{reduced_state | time_remaining: round_time_remaining(time_remaining)}
  end
  def trunc_times(auction_state), do: auction_state

  def round_time_remaining(time_remaining) do
    round(Float.round((time_remaining / 10_000), 0) * 10_000)
  end
end
