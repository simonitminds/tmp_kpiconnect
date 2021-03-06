defmodule Oceanconnect.Application do
  use Application

  alias Oceanconnect.Auctions.{
    AuctionsSupervisor,
    AuctionStoreStarter,
    FinalizedStateCache
  }

  alias Oceanconnect.Notifications.NotificationsSupervisor

  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications

  def start(_type, _args) do
    # Define workers and child supervisors to be supervised
    children =
      [
        # Start the Ecto repository
        Oceanconnect.Repo,

        # Start the endpoint when the application starts
        OceanconnectWeb.Endpoint,
        OceanconnectWeb.Telemetry,
        FinalizedStateCache,
        {Phoenix.PubSub, name: Oceanconnect.PubSub},
        {Registry, keys: :unique, name: :auction_supervisor_registry},
        {Registry, keys: :unique, name: :auctions_registry},
        {Registry, keys: :unique, name: :auction_cache_registry},
        {Registry, keys: :unique, name: :auction_event_handler_registry},
        {Registry, keys: :unique, name: :auction_scheduler_registry},
        {Registry, keys: :unique, name: :auction_timers_registry},
        {Registry, keys: :unique, name: :delayed_notifications_registry},
        {Task.Supervisor, name: Oceanconnect.Notifications.TaskSupervisor},
        {AuctionsSupervisor, restart: :permanent}
        # Start your own worker by calling: Oceanconnect.Worker.start_link(arg1, arg2, arg3)
      ]
      |> maybe_start_store()

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Oceanconnect.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    OceanconnectWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp maybe_start_store(children) do
    if Application.get_env(:oceanconnect, :exclude_optional_services) do
      children
    else
      children ++
        [
          AuctionStoreStarter,
          {NotificationsSupervisor, restart: :permanent}
        ]
    end
  end
end
