defmodule Oceanconnect.Notifications.EmailNotificationStore do
  use GenServer
  require Logger

  alias OceanconnectWeb.Mailer
  alias Oceanconnect.{Notifications, Auctions, Auctions.AuctionEvent}
  alias Oceanconnect.Auctions.{Auction, TermAuction}

  alias Oceanconnect.Notifications.{
    Command,
    DelayedNotifications,
    DelayedNotificationsSupervisor
  }

  @email_config Application.get_env(:oceanconnect, :emails, %{
                  auction_starting_soon_offset: 15 * 60 * 1_000,
                  delivered_coq_reminder_offset: 24 * 60 * 60 * 1_000
                })

  @delivery_events [
    :claim_created,
    :claim_response_created,
    :fixture_created,
    :fixture_updated,
    :fixture_delivered,
    :fixture_changes_proposed
  ]

  def start_link([]) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init([]) do
    subscribe_to_notifications()
    {:ok, []}
  end

  # Bamboo sends this message back on successful deliver from `deliver_later`.
  def handle_info({:delivered_email, _email}, state), do: {:noreply, state}

  def handle_info({:non_event_notification, type, data}, state) do
    process(:non_event_notification, type, data)

    {:noreply, state}
  end

  def handle_info({%AuctionEvent{type: type} = event, data}, state)
      when type in @delivery_events do
    process(event, data)

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

  defp process(:non_event_notification, type, data) do
    Notifications.emails_for_non_event(type, data)
    |> send()
  end

  defp process(event = %AuctionEvent{type: :auction_created, auction_id: auction_id}, state) do
    notification_name = "auction:#{auction_id}:upcoming_reminder"

    Notifications.emails_for_event(event, state)
    |> send()

    case DelayedNotificationsSupervisor.start_child(notification_name) do
      {:ok, _pid} ->
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

  defp process(
         event = %AuctionEvent{
           type: :auction_transitioned_from_draft_to_pending,
           auction_id: auction_id
         },
         state
       ) do
    notification_name = "auction:#{auction_id}:upcoming_reminder"

    Notifications.emails_for_event(event, state)
    |> send()

    case DelayedNotificationsSupervisor.start_child(notification_name) do
      {:ok, _pid} ->
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
          notification_name,
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

    Command.cancel_notification(notification_name, starting_soon_emails)
    |> DelayedNotifications.process_command()
  end

  defp process(event = %AuctionEvent{type: :auction_started, auction_id: auction_id}, _state) do
    notification_name = "auction:#{auction_id}:upcoming_reminder"

    Command.cancel_notification(notification_name, [])
    |> DelayedNotifications.process_command()
  end

  defp process(
         event = %AuctionEvent{
           type: :winning_solution_selected,
           auction_id: auction_id,
           data: %{solution: solution}
         },
         state
       ) do
    notification_name = "auction:#{auction_id}:coq_reminder"

    case DelayedNotificationsSupervisor.start_child(notification_name) do
      {:ok, _pid} ->
        auction = Oceanconnect.Auctions.get_auction!(auction_id)

        case calculate_upcoming_reminder_send_time(auction) do
          false ->
            {:ok, :nothing_to_schedule}

          send_time ->
            Command.schedule_reminder(notification_name, auction_id, send_time, solution)
            |> DelayedNotifications.process_command()
        end

      _ ->
        {:ok, :nothing_to_schedule}
    end
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
  def needs_processed?(%{auction_id: auction_id}) do
    result = Auctions.get_auction_status!(auction_id)
    result in [:open, :pending, :canceled, :expired, :closed]
  end

  defp calculate_upcoming_reminder_send_time(%Auction{auction_vessel_fuels: auction_vessel_fuels}) do
    earliest_eta =
      auction_vessel_fuels
      |> Enum.sort_by(&DateTime.to_unix(&1.eta))
      |> List.first()
      |> Map.get(:eta)

    if earliest_eta do
      DateTime.to_unix(earliest_eta, :millisecond)
      |> Kernel.-(@email_config.delivered_coq_reminder_offset)
      |> DateTime.from_unix!(:millisecond)
    else
      false
    end
  end

  defp calculate_upcoming_reminder_send_time(%TermAuction{}), do: false

  defp calculate_upcoming_reminder_send_time(auction_id) do
    %{scheduled_start: start_time} = Oceanconnect.Auctions.get_auction!(auction_id)

    if start_time do
      DateTime.to_unix(start_time, :millisecond)
      |> Kernel.-(@email_config.auction_starting_soon_offset)
      |> DateTime.from_unix!(:millisecond)
    else
      false
    end
  end
end
