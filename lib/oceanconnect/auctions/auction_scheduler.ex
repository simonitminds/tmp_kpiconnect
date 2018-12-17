defmodule Oceanconnect.Auctions.AuctionScheduler do
  use GenServer
  alias Oceanconnect.Auctions
  alias Oceanconnect.Auctions.{Auction, AuctionCache, Command, AuctionEvent}

  @registry_name :auction_scheduler_registry

  # Client
  def find_pid(auction_id) do
    with [{pid, _}] <- Registry.lookup(@registry_name, auction_id) do
      {:ok, pid}
    else
      [] -> {:error, "Auction Scheduler Not Started"}
    end
  end

  def timer_ref(auction_id, timer_type) do
    with {:ok, pid} <- find_pid(auction_id),
         {:ok, timer_ref} <- GenServer.call(pid, {:get_timer_ref, timer_type}),
         do: timer_ref
  end

  def cancel_timer(auction_id, timer_type) do
    with {:ok, pid} <- find_pid(auction_id),
         do: GenServer.cast(pid, {:cancel_timer, timer_type})
  end

  def start_link(%Auction{id: auction_id, scheduled_start: scheduled_start}) do
    GenServer.start_link(
      __MODULE__,
      {auction_id, scheduled_start},
      name: get_auction_scheduler_name(auction_id)
    )
  end

  def process_command(
        %Command{
          command: :update_scheduled_start,
          data: auction = %Auction{id: auction_id}
        },
        emit
      ) do
    with {:ok, pid} <- find_pid(auction_id),
         do: GenServer.cast(pid, {:update_scheduled_start, auction, emit})
  end

  def process_command(
        %Command{
          command: :cancel_scheduled_start,
          data: auction = %Auction{id: auction_id}
        },
        _emit
      ) do
    with {:ok, pid} <- find_pid(auction_id),
         do: GenServer.cast(pid, {:cancel_scheduled_start, auction})
  end

  # Server
  def init({auction_id, nil}),
    do: {:ok, %{auction_id: auction_id, scheduled_start: nil, timer_ref: nil}}

  def init({auction_id, scheduled_start}) do
    delay = get_schedule_delay(DateTime.diff(scheduled_start, DateTime.utc_now(), :millisecond))
    timer_ref = Process.send_after(self(), :start_auction, delay)
    {:ok, %{auction_id: auction_id, scheduled_start: scheduled_start, timer_ref: timer_ref}}
  end

  def handle_info(:start_auction, state = %{auction_id: auction_id}) do
    auction_id
    |> AuctionCache.read()
    |> Auctions.start_auction()

    {:noreply, state}
  end

  def handle_call(:get_timer_ref, _from, state = %{timer_ref: timer_ref}),
    do: {:reply, timer_ref, state}

  def handle_cast(
        {:update_scheduled_start, %{scheduled_start: scheduled_start}},
        state = %{scheduled_start: scheduled_start},
        _emit
      ) do
    IO.inspect("HEEEEEY")
    {:noreply, state}
  end

  def handle_cast(
        {:update_scheduled_start, auction = %Auction{scheduled_start: scheduled_start}, emit},
        state = %{timer_ref: nil}
      ) do
    delay = get_schedule_delay(DateTime.diff(scheduled_start, DateTime.utc_now(), :millisecond))
    timer_ref = Process.send_after(self(), :start_auction, delay)
    new_state = %{state | scheduled_start: scheduled_start, timer_ref: timer_ref}

    if emit do
      AuctionEvent.emit(AuctionEvent.auction_rescheduled(auction, nil), true)
    end

    {:noreply, new_state}
  end

  def handle_cast(
        {:update_scheduled_start,
         %{scheduled_start: scheduled_start, auction_started: auction_started}, _emit},
        state
      )
      when auction_started != nil do
    new_state = Map.put(state, :scheduled_start, scheduled_start)
    {:noreply, new_state}
  end

  def handle_cast(
        {:update_scheduled_start, %{scheduled_start: nil}, _emit},
        state = %{timer_ref: timer_ref}
      ) do
    cancel_timer(timer_ref)
    IO.inspect("BBBB")

    new_state =
      state
      |> Map.put(:timer_ref, nil)
      |> Map.put(:scheduled_start, nil)

    {:noreply, new_state}
  end

  def handle_cast(
        {:update_scheduled_start, auction = %Auction{scheduled_start: scheduled_start}, emit},
        state = %{timer_ref: timer_ref}
      ) do
    cancel_timer(timer_ref)
    delay = get_schedule_delay(DateTime.diff(scheduled_start, DateTime.utc_now(), :millisecond))
    new_timer_ref = Process.send_after(self(), :start_auction, delay)

    if emit do
      AuctionEvent.emit(AuctionEvent.auction_rescheduled(auction, nil), true)
    end

    new_state =
      state
      |> Map.put(:timer_ref, new_timer_ref)
      |> Map.put(:scheduled_start, scheduled_start)

    {:noreply, new_state}
  end

  def handle_cast(
        {:cancel_scheduled_start, %{scheduled_start: scheduled_start}},
        state = %{timer_ref: nil}
      ) do
    new_state = Map.put(state, :scheduled_start, scheduled_start)
    {:noreply, new_state}
  end

  def handle_cast(
        {:cancel_scheduled_start, %{scheduled_start: scheduled_start}},
        state = %{timer_ref: timer_ref}
      ) do
    cancel_timer(timer_ref)

    new_state =
      state
      |> Map.put(:scheduled_start, scheduled_start)
      |> Map.put(:timer_ref, nil)

    {:noreply, new_state}
  end

  # Private
  defp get_auction_scheduler_name(auction_id) do
    {:via, Registry, {@registry_name, auction_id}}
  end

  defp get_schedule_delay(delay) when delay <= 0, do: 500
  defp get_schedule_delay(delay), do: delay

  defp cancel_timer(nil), do: :ok
  defp cancel_timer(timer_ref), do: Process.cancel_timer(timer_ref)
end
