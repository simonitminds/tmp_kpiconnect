defmodule Oceanconnect.Auctions.AuctionsSupervisor do
  # Automatically defines child_spec/1
  use DynamicSupervisor

  def start_link() do
    DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init([]) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_child(auction_id) do
    DynamicSupervisor.start_child(__MODULE__, {Oceanconnect.Auctions.AuctionStore, auction_id})
  end
end


# defmodule VehicleTracker.Fleet.TrackerSupervisor do
#   use Supervisor
#   alias VehicleTracker.Fleet.TrackerLocationUpdater
#   require Logger
#
#   def start_link() do
#     Supervisor.start_link(__MODULE__, [], name: :tracker_supervisor)
#   end
#
#   def init(_) do
#     children = [
#       worker(TrackerLocationUpdater, [], restart: :transient),
#     ]
#
#     supervise(children, strategy: :simple_one_for_one)
#   end
#
#   def start_location_updater(imei) do
#     Logger.info("Starting Tracker for #{inspect(imei)}")
#     Supervisor.start_child(:tracker_supervisor, [imei])
#   end
#
#   def stop_location_updater(imei) do
#     with [{pid, _}] <- Registry.lookup(:active_trackers_registry, imei) do
#       GenServer.stop(pid, :normal)
#     else
#       [] -> {:error, "Not Started"}
#     end
#   end
#
#   def location_updater_started?(imei) do
#     with [{_pid, _}] <- Registry.lookup(:active_trackers_registry, imei) do
#       true
#     else
#       [] -> false
#     end
#   end
# end
