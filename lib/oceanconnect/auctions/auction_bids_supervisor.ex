defmodule Oceanconnect.Auctions.AuctionBidsSupervisor do
  # Automatically defines child_spec/1
  use DynamicSupervisor

  def start_link() do
    DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init([]) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_child(auction_id) do
    DynamicSupervisor.start_child(__MODULE__, {Oceanconnect.Auctions.AuctionBidList, auction_id})
  end
end
