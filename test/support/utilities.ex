defmodule Oceanconnect.Utilities do
  alias Oceanconnect.Auctions.AuctionStore.AuctionState
  alias Oceanconnect.Auctions.AuctionTimer

  def trunc_times(auction_state = %{time_remaining: time_remaining, current_server_time: current_time}) do
    trunc_time = %{current_time | microsecond: {0, 0}}

    %{auction_state | time_remaining: round_time_remaining(time_remaining), current_server_time: trunc_time}
  end

  def round_time_remaining(time_remaining) do
    round(Float.round((time_remaining / 10_000), 0) * 10_000)
  end
end
