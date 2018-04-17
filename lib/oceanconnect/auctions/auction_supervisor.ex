defmodule Oceanconnect.Auctions.AuctionSupervisor do
  use Supervisor
  @registry_name :auction_supervisor_registry
  alias Oceanconnect.Auctions.{Auction,
                               AuctionCache,
                               AuctionBidList,
                               AuctionEventHandler,
                               AuctionEventStore,
                               AuctionStore,
                               AuctionTimer}

  def start_link(auction = %Auction{id: auction_id}) do
    Supervisor.start_link(__MODULE__, auction, name: get_auction_supervisor_name(auction_id))
  end

  def init(auction = %Oceanconnect.Auctions.Auction{id: auction_id, duration: duration, decision_duration: decision_duration}) do
    children = [
      {AuctionCache, auction},
      {AuctionStore, auction_id},
      {AuctionBidList, auction_id},
      {AuctionEventStore, auction_id},
      {AuctionEventHandler, auction_id},
      {AuctionTimer, {auction_id, duration, decision_duration}},
    ]
    Supervisor.init(children, strategy: :one_for_all)
  end

  defp get_auction_supervisor_name(auction_id) do
    {:via, Registry, {@registry_name, auction_id}}
  end

  def find_pid(auction_id) do
    with [{pid, _}] <- Registry.lookup(@registry_name, auction_id) do
      {:ok, pid}
    else
      [] -> {:error, "Auction Supervisor Not Started"}
    end
  end
end
