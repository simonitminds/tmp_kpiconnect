defmodule Oceanconnect.Notifications.EmailNotificationStore do
  use GenServer
  alias Oceanconnect.Notifications

  @task_supervisor Application.get_env(:oceanconnect, :task_supervisor) || Task.Supervisor
  @task_supervisor_name Oceanconnect.Notifications.TaskSupervisor

  def start_link() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init([]) do
    subscribe_to_notifications()
  end

  def process({event, state}) do
    emails = Notifications.emails_for_event(event, state)
    Enum.map(emails, fn(email) ->
      Oceanconnect.Mailer.deliver_later(email)
    end)
  end

  defp subscribe_to_notifications() do
    Phoenix.PubSub.subscribe(:auction_pubsub, "auctions")
  end
end
