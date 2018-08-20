defmodule Oceanconnect.Auctions.AuctionSupervisor do
  use Supervisor
  @registry_name :auction_supervisor_registry
  alias Oceanconnect.Auctions.{
    Auction,
    AuctionCache,
    AuctionEventHandler,
    AuctionEmailNotificationHandler,
    AuctionEventStore,
    AuctionScheduler,
    AuctionStore,
    AuctionTimer,
    AuctionReminderTimer
  }

  def start_link({auction = %Auction{id: auction_id}, config}) do
    Supervisor.start_link(
      __MODULE__,
      {auction, config},
      name: get_auction_supervisor_name(auction_id)
    )
  end

  def init({auction = %Auction{id: auction_id}, options}) do
    all_children = %{
      auction_a_timer: {AuctionTimer, auction_id},
      auction_cache: {AuctionCache, auction},
      auction_event_handler: {AuctionEventHandler, auction_id},
      auction_email_notification_handler: {AuctionEmailNotificationHandler, auction_id},
      auction_event_store: {AuctionEventStore, auction_id},
      auction_scheduler: {AuctionScheduler, auction},
      auction_store: {AuctionStore, auction},
      auction_reminder_timer:
        Supervisor.child_spec({AuctionReminderTimer, auction}, restart: :transient)
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
    children =
      if :auction_reminder_timer in exclusions do
        Enum.reject(all_children, fn child -> child == :auction_reminder_timer end)
      else
        all_children
      end

    children_included = children
    |> Enum.reject(fn {k, _v} -> k in exclusions end)
    |> Enum.map(fn {_, v} -> v end)

    children_included
  end

  defp exclude_children(all_children, %{}), do: all_children |> Map.values()
end
