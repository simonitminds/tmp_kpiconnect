defmodule Oceanconnect.Notifications.NotificationsSupervisor do
  use Supervisor
  alias Oceanconnect.Notifications.NotificationStore

  def start_link() do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init({%struct{id: auction_id}, _options}) when is_auction(struct) do
    children = [
      {NotificationStore, []}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
