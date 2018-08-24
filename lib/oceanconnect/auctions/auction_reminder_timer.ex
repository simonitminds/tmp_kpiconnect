defmodule Oceanconnect.Auctions.AuctionReminderTimer do
  use GenServer
  alias Oceanconnect.Auctions.{Auction, AuctionEvent}

  @registry_name :auction_reminder_timers_registry

  # Client
  def find_pid(auction_id) do
    with [{pid, _}] <- Registry.lookup(@registry_name, auction_id) do
      {:ok, pid}
    else
      [] -> {:error, "Auction Timer Not Started"}
    end
  end

  def start_link([auction = %Auction{id: auction_id}]) do
    GenServer.start_link(__MODULE__, auction, name: get_reminder_timer_name(auction_id))
  end

  def init(auction = %Auction{scheduled_start: start_time}) do
    duration = DateTime.to_unix(start_time, :millisecond) - DateTime.to_unix(DateTime.utc_now(), :millisecond) - 3_600_000
    Process.send_after(self(), {:remind_participants, auction}, max(0, duration))
    {:ok, start_time}
  end

  def handle_info({:remind_participants, auction = %Auction{}}, _state) do
    AuctionEvent.emit(AuctionEvent.upcoming_auction_notified(auction), true)
    {:stop, :normal}
  end
  # private
  defp get_reminder_timer_name(auction_id) do
    {:via, Registry, {@registry_name, auction_id}}
  end

  def terminate(reason) do
    if reason == :normal || reason == :shutdown do
      {:ok, :shutdown}
    end
  end
end
