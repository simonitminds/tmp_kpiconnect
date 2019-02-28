defmodule Oceanconnect.Notifications.EmailNotificationStore do
  use GenServer
  require Logger

  alias OceanconnectWeb.Mailer
  alias Oceanconnect.Notifications
  alias Oceanconnect.Notifications.{
    Command,
    DelayedNotification
  }

  def start_link([]) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init([]) do
    subscribe_to_notifications()
    {:ok, []}
  end

  # Bamboo sends this message back on successful deliver from `deliver_later`.
  def handle_info({:delivered_email, _email}, state) do
    {:noreply, state}
  end

  def handle_info({event, event_state}, state) do
    process(event, event_state)
    {:noreply, state}
  end

  def handle_info(msg, state) do
    Logger.warn("EmailNotificationStore received an unexpected message: #{inspect(msg)}")
    {:noreply, state}
  end


  defp process(event = %AuctionEvent{type: :auction_created, auction_id: auction_id}, state) do
    NotificationCommand.schedule_notification("auction:#{auction_id}:upcoming_reminder")
    |> DelayedNotifications.process_command()
  end

  defp process(event = %AuctionEvent{type: :auction_rescheduled, auction_id: auction_id}, state) do
    NotificationCommand.reschedule_notification("auction:#{auction_id}:upcoming_reminder")
    |> DelayedNotifications.process_command()
  end

  defp process(event = %AuctionEvent{type: :auction_canceled, auction_id: auction_id}, state) do
    NotificationCommand.cancel_notification("auction:#{auction_id}:upcoming_reminder")
    |> DelayedNotifications.process_command()
  end

  defp process(event = %AuctionEvent{type: :auction_started, auction_id: auction_id}, state) do
    NotificationCommand.cancel_notification("auction:#{auction_id}:upcoming_reminder")
    |> DelayedNotifications.process_command()
  end


  defp process(event, state) do
    emails = Notifications.emails_for_event(event, state)
    Enum.map(emails, fn(email) ->
      Mailer.deliver_later(email)
    end)
  end


  defp subscribe_to_notifications() do
    Phoenix.PubSub.subscribe(:auction_pubsub, "auctions")
  end
end
