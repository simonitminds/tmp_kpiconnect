defmodule Oceanconnect.Notifications.EmailNotificationStore do
  use GenServer
  require Logger

  alias OceanconnectWeb.Mailer
  alias Oceanconnect.Auctions.AuctionEvent
  alias Oceanconnect.Notifications

  alias Oceanconnect.Notifications.{
    Command,
    DelayedNotifications,
    DelayedNotificationsSupervisor
  }

  def start_link([]) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init([]) do
    subscribe_to_notifications()
    {:ok, []}
  end

  # Bamboo sends this message back on successful deliver from `deliver_later`.
  def handle_info({:delivered_email, email}, state) do
    {:noreply, state}
  end

  def handle_info({event, event_state}, state) do
    if needs_processed?(event) do
      process(event, event_state)
    end

    {:noreply, state}
  end

  def handle_info(msg, state) do
    Logger.warn("EmailNotificationStore received an unexpected message: #{inspect(msg)}")
    {:noreply, state}
  end

  defp process(event = %AuctionEvent{type: :auction_created, auction_id: auction_id}, state) do
    notification_name = "auction:#{auction_id}:upcoming_reminder"

    Notifications.emails_for_event(event, state)
    |> send()

    case DelayedNotificationsSupervisor.start_child(notification_name) do
      {:ok, pid} ->
        starting_soon_emails =
          Notifications.emails_for_event(%AuctionEvent{type: :upcoming_auction_notified}, state)

        case calculate_upcoming_reminder_send_time(auction_id) do
          false ->
            {:ok, :nothing_to_schedule}

          send_time ->

            Command.schedule_notification(notification_name, send_time, starting_soon_emails)
            |> DelayedNotifications.process_command()
        end

      _ ->
        {:ok, :nothing_to_schedule}
    end
  end

  defp process(event = %AuctionEvent{type: :auction_rescheduled, auction_id: auction_id}, state) do
    notification_name = "auction:#{auction_id}:upcoming_reminder"

    Notifications.emails_for_event(event, state)
    |> send()

    starting_soon_emails =
      Notifications.emails_for_event(%AuctionEvent{type: :upcoming_auction_notified}, state)

    case calculate_upcoming_reminder_send_time(auction_id) do
      false ->
        {:ok, :nothing_to_schedule}

      send_time ->
        Command.reschedule_notification(
          "auction:#{auction_id}:upcoming_reminder",
          send_time,
          starting_soon_emails
        )
        |> DelayedNotifications.process_command()
    end
  end

  defp process(event = %AuctionEvent{type: :auction_canceled, auction_id: auction_id}, state) do
    notification_name = "auction:#{auction_id}:upcoming_reminder"

    Notifications.emails_for_event(event, state)
    |> send()

    starting_soon_emails =
      Notifications.emails_for_event(%AuctionEvent{type: :upcoming_auction_notified}, state)

    Command.cancel_notification("auction:#{auction_id}:upcoming_reminder", starting_soon_emails)
    |> DelayedNotifications.process_command()
  end

  defp process(event = %AuctionEvent{type: :auction_started, auction_id: auction_id}, state) do
    notification_name = "auction:#{auction_id}:upcoming_reminder"

    Command.cancel_notification("auction:#{auction_id}:upcoming_reminder", [])
    |> DelayedNotifications.process_command()
  end

  defp process(event, state) do
    Notifications.emails_for_event(event, state)
    |> send()
  end

  defp send(emails) do
    Enum.map(emails, fn email ->
      Mailer.deliver_later(email)
    end)
  end

  defp subscribe_to_notifications() do
    Phoenix.PubSub.subscribe(:auction_pubsub, "auctions")
  end

  # TODO IMPLEMENT THIS WITH NEW SENT EVENTS FOR EMAILS
  def needs_processed?(_event) do
    true
  end

  defp calculate_upcoming_reminder_send_time(auction_id) do
    %{scheduled_start: start_time} = Oceanconnect.Auctions.get_auction!(auction_id)

    if start_time do
      DateTime.to_unix(start_time, :millisecond)
      |> Kernel.-(3_600_000)
      |> DateTime.from_unix!(:millisecond)
    else
      false
    end
  end
end
