defmodule Oceanconnect.Auctions.FinalizedStateCacheSupervisor do
  use Supervisor
  alias Oceanconnect.Auctions.FinalizedStateCache

  def start_link(_) do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init([]) do
    children = [
      worker(FinalizedStateCache, restart: :transient)
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
