defmodule Oceanconnect.Notifications.DelayedNotifications do
  use GenServer

  alias Oceanconnect.Auctions.{
    AuctionEvent,
    AuctionEventStore,
    AuctionStore
  }
  alias Oceanconnect.Notifications.Command
  alias OceanconnectWeb.Mailer

  # Client
  @registry_name :delayed_notifications_registry

  def find_pid(notification_name) do
    with [{pid, _}] <- Registry.lookup(@registry_name, notification_name) do
      {:ok, pid}
    else
      [] -> {:error, "Notification Timer for #{notification_name}"}
    end
  end

  def start_link() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def process_command(command = %Command{name: name}) do
    with {:ok, pid} <- find_pid(name),
        do: GenServer.cast(pid, {:process, command})
  end



  def init([]) do
    {:ok, %{
      timer_ref: nil,
      send_time: nil,
      emails: []
    }}
  end

  def handle_cast({:process, command = %Command{}, state) do
    new_state = process(command, state)
    {:noreply, state}
  end

  def handle_cast({:send_now}, state = %{timer_ref: ref, emails: emails}) do
    cancel_timer(ref)
    send(emails)

    {:noreply, %{state | timer_ref: nil}}
  end


  def process(
        %Command{command: :schedule_notification, name: name, data: %{send_time: send_time},
        state = %{timer_ref: nil}
      ) do
    delay = time_until(send_time)
    ref = Process.send_after(self(), :send_now, delay)

    {:ok, %{state | timer_ref: ref}}
  end

  def process(
        %Command{command: :reschedule_notification, name: name, data: %{send_time: new_send_time},
        state = %{timer_ref: ref, send_time: send_time}
      ) do
    if send_time == new_send_time do
      cancel_timer(ref)
      delay = time_until(new_send_time)
      ref = Process.send_after(self(), :send_now, delay)
      {:ok, %{state | timer_ref: ref}}
    else
      {:ok, state}
    end
  end

  def process(
        %Command{command: :cancel_notification, name: name, data: %{},
        state = %{timer_ref: ref}
      ) do
    cancel_timer(ref)
    {:ok, %{state | timer_ref: nil}}
  end



  defp send(emails) do
    Enum.map(emails, fn(email) ->
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









  # def init(auction = %struct{id: auction_id, scheduled_start: start_time}) when is_auction(struct) do
  #   AuctionEventStore.event_list(auction_id)

  #   if Enum.any?(AuctionEventStore.event_list(auction_id), fn event ->
  #        if(%AuctionEvent{} = event) do
  #          event.type == :upcoming_auction_notified
  #        else
  #          :erlang.binary_to_term(event).type == :upcoming_auction_notified
  #        end
  #      end) do
  #     Process.send_after(self(), :shutdown_timer, 5_000)
  #     {:ok, start_time}
  #   else
  #     duration =
  #       DateTime.to_unix(start_time, :millisecond) -
  #         DateTime.to_unix(DateTime.utc_now(), :millisecond) - 3_600_000

  #     Process.send_after(self(), {:remind_participants, auction}, max(0, duration))
  #     {:ok, start_time}
  #   end
  # end

  # def handle_info(:shutdown_timer, state) do
  #   {:stop, :normal, state}
  # end

  # def handle_info({:remind_participants, auction = %struct{}}, state) when is_auction(struct) do
  #   Command.notify_upcoming_auction(auction, nil)
  #   |> AuctionStore.process_command()
  #   {:stop, :normal, state}
  # end


  # def terminate(reason) do
  #   if reason == :normal || reason == :shutdown do
  #     {:ok, :shutdown}
  #   end
  # end
end
