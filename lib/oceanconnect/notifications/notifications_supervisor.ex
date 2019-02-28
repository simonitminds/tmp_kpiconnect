defmodule Oceanconnect.Notifications.NotificationsSupervisor do
  use Supervisor
  alias Oceanconnect.Notifications.EmailNotificationStore
  import Oceanconnect.Auctions.Guards

  def start_link() do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init([]) do
    children = [
      {EmailNotificationStore, []}
      {ChannelNotifier, []},
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
