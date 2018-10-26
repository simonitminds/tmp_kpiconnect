defmodule Oceanconnect.Application do
  use Application
  alias Oceanconnect.Auctions.{AuctionsSupervisor, AuctionStoreStarter}
  import Supervisor.Spec

  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications

  def start(_type, _args) do
    # Define workers and child supervisors to be supervised
    children =
      [
        # Start the Ecto repository
        supervisor(Oceanconnect.Repo, []),
        # Start the endpoint when the application starts
        supervisor(OceanconnectWeb.Endpoint, []),
        supervisor(Phoenix.PubSub.PG2, [:auction_pubsub, []]),
        {Registry, keys: :unique, name: :auction_supervisor_registry},
        {Registry, keys: :unique, name: :auction_email_supervisor_registry},
        {Registry, keys: :unique, name: :auctions_registry},
        {Registry, keys: :unique, name: :auction_cache_registry},
        {Registry, keys: :unique, name: :auction_timers_registry},
        {Registry, keys: :unique, name: :auction_reminder_timers_registry},
        {Registry, keys: :unique, name: :auction_scheduler_registry},
        {Registry, keys: :unique, name: :auction_bids_registry},
        {Registry, keys: :unique, name: :auction_event_store_registry},
        {Registry, keys: :unique, name: :auction_event_handler_registry},
        {Registry, keys: :unique, name: :auction_email_notification_handler_registry},
        worker(AuctionsSupervisor, [], restart: :permanent)
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
    if(Application.get_env(:oceanconnect, :store_starter)) do
      children
    else
      children ++ [worker(AuctionStoreStarter, [])]
    end
  end
end
