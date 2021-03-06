defmodule Oceanconnect.Auctions.AuctionEventStoreSupervisor do
  # Automatically defines child_spec/1
  use DynamicSupervisor

  def start_link() do
    DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init([]) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_child(auction) do
    DynamicSupervisor.start_child(__MODULE__, {Oceanconnect.Auctions.AuctionEventStore, auction})
  end
end
