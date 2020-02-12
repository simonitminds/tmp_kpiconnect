defmodule Oceanconnect.Notifications.DelayedNotifications do
  use GenServer

  alias Oceanconnect.Notifications.{Command, Emails}
  alias OceanconnectWeb.Mailer

  # Client
  @registry_name :delayed_notifications_registry

  def find_pid(notification_name) do
    with [{pid, _}] <- Registry.lookup(@registry_name, notification_name) do
      {:ok, pid}
    else
      [] ->
        {:error, "Notification Timer for #{notification_name}"}
    end
  end

  defp get_delayed_notification_name(notification_name) do
    {:via, Registry, {@registry_name, notification_name}}
  end

  def start_link(name) do
    GenServer.start_link(__MODULE__, name, name: get_delayed_notification_name(name))
  end

  def process_command(command = %Command{notification_name: notification_name}) do
    with {:ok, pid} <- find_pid(notification_name),
         do: GenServer.cast(pid, {:process, command})
  end

  def init(name) do
    {:ok,
     %{
       name: name,
       timer_ref: nil,
       send_time: nil,
       emails: []
     }}
  end

  def handle_cast({:process, command = %Command{}}, state) do
    {:ok, new_state} = process(command, state)
    {:noreply, new_state}
  end

  def handle_info(:send_now, state = %{timer_ref: ref, emails: emails}) do
    cancel_timer(ref)
    send(emails)

    {:noreply, %{state | timer_ref: nil}}
  end

  def handle_info(
        :send_reminder,
        state = %{auction_id: auction_id, solution: solution, timer_ref: ref}
      ) do
    cancel_timer(ref)

    auction_id
    |> Emails.DeliveredCOQReminder.generate(solution)
    |> send()

    {:noreply, %{state | timer_ref: nil}}
  end

  defp process(
         %Command{
           command: :schedule_reminder,
           data: %{auction_id: auction_id, send_time: send_time, solution: solution}
         },
         state = %{timer_ref: nil}
       ) do
    delay = time_until(send_time)
    ref = Process.send_after(self(), :send_reminder, delay)

    {:ok,
     %{state | auction_id: auction_id, send_time: send_time, solution: solution, timer_ref: ref}}
  end

  defp process(
         %Command{command: :schedule_notification, data: %{send_time: send_time, emails: emails}},
         state = %{timer_ref: nil}
       ) do
    delay = time_until(send_time)
    ref = Process.send_after(self(), :send_now, delay)

    {:ok, %{state | timer_ref: ref, emails: emails, send_time: send_time}}
  end

  defp process(
         %Command{
           command: :reschedule_notification,
           data: %{send_time: new_send_time, emails: emails}
         },
         state = %{timer_ref: ref, send_time: send_time}
       ) do
    if send_time != new_send_time do
      cancel_timer(ref)
      delay = time_until(new_send_time)
      ref = Process.send_after(self(), :send_now, delay)
      {:ok, %{state | timer_ref: ref, emails: emails, send_time: new_send_time}}
    else
      {:ok, state}
    end
  end

  defp process(%Command{command: :cancel_notification}, state = %{timer_ref: ref}) do
    cancel_timer(ref)
    {:ok, %{state | timer_ref: nil}}
  end

  defp send(emails) do
    Enum.map(emails, fn email ->
      Mailer.deliver_later(email)
    end)
  end

  defp cancel_timer(nil), do: :ok
  defp cancel_timer(timer_ref), do: Process.cancel_timer(timer_ref)

  defp time_until(send_time) do
    send_time
    |> DateTime.diff(DateTime.utc_now(), :millisecond)
    |> normalize_delay()
  end

  defp normalize_delay(delay) when delay <= 0, do: 500
  defp normalize_delay(delay), do: delay
end
