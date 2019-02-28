defmodule Oceanconnect.Notifications.EmailNotificationStore do
  use GenServer
  alias Oceanconnect.Notifications
  alias OceanconnectWeb.Mailer
  require Logger

  def start_link([]) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init([]) do
    subscribe_to_notifications()
    {:ok, []}
  end

  def process({event, state}) do
    emails = Notifications.emails_for_event(event, state)
    Enum.map(emails, fn(email) ->
      Mailer.deliver_later(email)
    end)
  end

  def handle_info({event = %event_struct{}, event_state}, state), when is_struct(event_struct) do
    process(event, event_state)
    {:noreply, state}
  end

  def handle_info(msg, state) do
    Logger.warn("EmailNotificationStore received an unexpected message: #{inspect(msg)}")
    {:noreply, state}
  end

  defp subscribe_to_notifications() do
    Phoenix.PubSub.subscribe(:auction_pubsub, "auctions")
  end
end
