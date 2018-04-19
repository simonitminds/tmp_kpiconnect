defmodule Oceanconnect.Auctions.AuctionTimer do
  use GenServer
  alias __MODULE__
  alias Oceanconnect.Auctions.{Auction, AuctionStore, Command}

  @registry_name :auction_timers_registry
  @extension_time 3 * 60_000

  def find_pid(auction_id) do
    with [{pid, _}] <- Registry.lookup(@registry_name, auction_id) do
      {:ok, pid}
    else
      [] -> {:error, "Auction Timer Not Started"}
    end
  end

  def timer_ref(auction_id, type) do
    with {:ok, pid}       <- find_pid(auction_id),
         {:ok, timer_ref} <- GenServer.call(pid, {:get_timer_ref, type}),
         do: timer_ref
  end

  defp get_auction_timer_name(auction_id) do
    {:via, Registry, {@registry_name, auction_id}}
  end

  # Client
  def start_link({auction_id, duration, decision_duration}) do
    GenServer.start_link(__MODULE__, {auction_id, duration, decision_duration}, name: get_auction_timer_name(auction_id))
  end

  def process_command(%Command{command: :start_duration_timer, data: %{id: auction_id, duration: duration}}) do
    with {:ok, pid} <- find_pid(auction_id),
      do: GenServer.cast(pid, {:start_duration_timer, duration, pid})
  end

  def process_command(%Command{command: :start_decision_duration_timer, data: %{id: auction_id, decision_duration: decision_duration}}) do
    with {:ok, pid} <- find_pid(auction_id),
      do: GenServer.cast(pid, {:start_decision_duration_timer, decision_duration, pid})
  end

  def process_command(%Command{command: :extend_duration, data: %{auction_id: auction_id}}) do
    with {:ok, pid} <- find_pid(auction_id),
      do: GenServer.call(pid, {:extend_duration, pid})
  end

  # Server
  def init({auction_id, duration, decision_duration}) do
    {:ok, %{auction_id: auction_id, duration: duration, duration_timer: nil,
            decision_duration: decision_duration, decision_duration_timer: nil}}
  end

  def handle_info(:end_auction_timer, state = %{auction_id: auction_id, decision_duration: decision_duration}) do
    %Auction{id: auction_id, decision_duration: decision_duration}
    |> Command.end_auction
    |> AuctionStore.process_command

    {:noreply, state}
  end

  def handle_info(:end_auction_decision_timer, state = %{auction_id: auction_id}) do
    %Auction{id: auction_id}
    |> Command.end_auction_decision_period
    |> AuctionStore.process_command

    {:noreply, state}
  end

  def handle_call({:get_timer_ref, :duration}, _from, state = %{duration_timer: timer_ref}) do
    {:reply, timer_ref, state}
  end
  def handle_call({:get_timer_ref, :decision_duration}, _from, state = %{decision_duration_timer: timer_ref}) do
    {:reply, timer_ref, state}
  end

  def handle_cast({:start_duration_timer, duration, pid}, current_state) do
    new_timer = create_timer(pid, duration, :duration)
    new_state = Map.put(current_state, :duration_timer, new_timer)
    {:noreply, new_state}
  end

  def handle_cast({:start_decision_duration_timer, decision_duration, pid}, current_state) do
    new_timer = create_timer(pid, decision_duration, :decision_duration)
    new_state = Map.put(current_state, :decision_duration_timer, new_timer)
    {:noreply, new_state}
  end

  def handle_call({:extend_duration, pid}, _from, current_state = %{duration_timer: duration_timer}) do
    new_state = case Process.cancel_timer(duration_timer) do
      false -> current_state
      _ ->
        new_timer = create_timer(pid, @extension_time, :duration)
        Map.put(current_state, :duration_timer, new_timer)
    end
    {:reply, new_state, new_state}
  end

  defp create_timer(pid, duration, _type = :duration) do
    Process.send_after(pid, :end_auction_timer, duration)
  end
  defp create_timer(pid, duration, _type = :decision_duration) do
    Process.send_after(pid, :end_auction_decision_timer, duration)
  end

  # Client
  def get_timer(pid) do
    GenServer.call(pid, :get_timer_ref)
  end

  def extend_auction?(auction_id) do
    time_remaining = Process.read_timer(AuctionTimer.timer_ref(auction_id, :duration))
    case time_remaining <= @extension_time do
      true ->
        auction_id
        |> Command.extend_duration
        |> AuctionTimer.process_command
        {true, @extension_time}
      _ -> {false, time_remaining}
    end
  end

  def cancel_timer(auction_id, timer_type) do
    auction_id
    |> AuctionTimer.timer_ref(timer_type)
    |> Process.cancel_timer
  end
end
