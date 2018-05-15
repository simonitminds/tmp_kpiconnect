defmodule Oceanconnect.Auctions.AuctionsSupervisor do
  # Automatically defines child_spec/1
  use DynamicSupervisor

  def start_link() do
    DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init([]) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_child(auction = %Oceanconnect.Auctions.Auction{}) do
    DynamicSupervisor.start_child(__MODULE__, {Oceanconnect.Auctions.AuctionSupervisor, {auction, %{exclude_children: []}}})
  end
end
