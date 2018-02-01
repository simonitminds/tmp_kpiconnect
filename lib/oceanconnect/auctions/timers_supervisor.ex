defmodule Oceanconnect.Auctions.TimersSupervisor do
  # Automatically defines child_spec/1
  use DynamicSupervisor

  def start_link() do
    DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init([]) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_timer(%Oceanconnect.Auctions.Auction{id: id}) do
    DynamicSupervisor.start_child(__MODULE__, {Oceanconnect.Auctions.AuctionTimer, id})
  end
end
