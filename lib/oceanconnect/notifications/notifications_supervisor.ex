defmodule Oceanconnect.Notifications.NotificationsSupervisor do
  use Supervisor
  alias Oceanconnect.Notifications.{EmailNotificationStore, DelayedNotificationsSupervisor}

  def start_link() do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init([]) do
    children = [
      {EmailNotificationStore, []},
      {DelayedNotificationsSupervisor, []}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
