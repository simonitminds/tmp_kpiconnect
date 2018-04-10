defmodule Oceanconnect.Auctions.AuctionSupervisor do
  use Supervisor
  @registry_name :auction_supervisor_registry

  def start_link(auction_id) do
    Supervisor.start_link(__MODULE__, auction_id, name: get_auction_supervisor_name(auction_id))
  end

  def init(auction_id) do
    children = [
      {Oceanconnect.Auctions.AuctionStore, auction_id},
      {Oceanconnect.Auctions.AuctionBidList, auction_id},
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
