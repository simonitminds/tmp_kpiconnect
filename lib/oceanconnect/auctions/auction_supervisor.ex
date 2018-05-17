defmodule Oceanconnect.Auctions.AuctionSupervisor do
  use Supervisor
  @registry_name :auction_supervisor_registry
  alias Oceanconnect.Auctions.{Auction,
                               AuctionCache,
                               AuctionBidList,
                               AuctionEventHandler,
                               AuctionEventStore,
                               AuctionScheduler,
                               AuctionStore,
                               AuctionTimer}

  def start_link({auction = %Auction{id: auction_id}, config}) do
    Supervisor.start_link(__MODULE__, {auction, config}, name: get_auction_supervisor_name(auction_id))
  end


  def init({auction = %Auction{id: auction_id}, options}) do
    all_children = %{
      auction_a_timer: {AuctionTimer, auction_id},
      auction_bid_list: {AuctionBidList, auction_id},
      auction_cache: {AuctionCache, auction},
      auction_event_handler: {AuctionEventHandler, auction_id},
      auction_event_store: {AuctionEventStore, auction_id},
      auction_scheduler: {AuctionScheduler, auction},
      auction_store: {AuctionStore, auction}
    }
    children = exclude_children(all_children, options)
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

  defp exclude_children(all_children, %{exclude_children: exclusions}) do
    all_children
    |> Enum.filter(fn({k, _v}) -> not k in exclusions end)
    |> Enum.map(fn({_, v}) -> v end)
  end
  defp exclude_children(all_children, %{}), do: all_children |> Map.values
end
