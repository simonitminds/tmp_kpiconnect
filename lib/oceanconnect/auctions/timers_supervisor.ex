defmodule Oceanconnect.Auctions.TimersSupervisor do
  # Automatically defines child_spec/1
  use DynamicSupervisor

  def start_link() do
    DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init([]) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_timer({auction_id, type_duration, type}) do
    DynamicSupervisor.start_child(__MODULE__, {Oceanconnect.Auctions.AuctionTimer, {auction_id, type_duration, type}})
  end
end
