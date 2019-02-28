defmodule Oceanconnect.Notifications.NotificationsSupervisor do
  use Supervisor
  alias Oceanconnect.Notifications.EmailNotificationStore

  def start_link() do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init([]) do
    children = [
      {EmailNotificationStore, []},
      {DelayedNotifications, []}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
