defmodule Oceanconnect.Auctions.AuctionSupervisor do
  use Supervisor

  import Oceanconnect.Auctions.Guards

  alias Oceanconnect.Auctions.{
    AuctionCache,
    AuctionEventHandler,
    AuctionScheduler,
    AuctionStore,
    AuctionTimer
  }

  @registry_name :auction_supervisor_registry

  def start_link({auction = %struct{id: auction_id}, config})
      when is_auction(struct) do
    Supervisor.start_link(
      __MODULE__,
      {auction, config},
      name: get_auction_supervisor_name(auction_id)
    )
  end

  def init({auction = %struct{id: auction_id}, options})
      when is_auction(struct) do
    all_children = %{
      auction_a_timer: {AuctionTimer, auction_id},
      auction_cache: {AuctionCache, auction},
      auction_event_handler: {AuctionEventHandler, auction_id},
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
    children_included =
      all_children
      |> Enum.reject(fn {k, _v} -> k in exclusions end)
      |> Enum.map(fn {_, v} -> v end)

    children_included
  end

  defp exclude_children(all_children, %{}), do: all_children |> Map.values()
end
