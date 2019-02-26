defmodule Oceanconnect.Auctions.AuctionTimer do
  use GenServer

  import Oceanconnect.Auctions.Guards

  alias __MODULE__
  alias Oceanconnect.Auctions
  alias Oceanconnect.Auctions.{Command}

  @registry_name :auction_timers_registry
  @extension_time 3 * 60_000

  # Client
  def find_pid(auction_id) do
    with [{pid, _}] <- Registry.lookup(@registry_name, auction_id) do
      {:ok, pid}
    else
      [] -> {:error, "Auction Timer Not Started"}
    end
  end

  def timer_ref(auction_id, timer_type) do
    with {:ok, pid} <- find_pid(auction_id),
         {:ok, timer_ref} <- GenServer.call(pid, {:get_timer_ref, timer_type}),
         do: timer_ref
  end

  def read_timer(auction_id, timer_type) do
    with {:ok, pid} <- find_pid(auction_id),
         {:ok, timer_ref} <- GenServer.call(pid, {:get_timer_ref, timer_type}),
         false <- timer_ref == nil do
      Process.read_timer(timer_ref)
    else
      _ -> false
    end
  end

  def cancel_timer(auction_id, timer_type) do
    with {:ok, pid} <- find_pid(auction_id),
         do: GenServer.cast(pid, {:cancel_timer, timer_type})
  end

  def start_link(auction_id) do
    GenServer.start_link(__MODULE__, auction_id, name: get_auction_timer_name(auction_id))
  end

  def process_command(%Command{
        command: :start_duration_timer,
        data: auction = %struct{id: auction_id}
      }) when is_auction(struct) do
    with {:ok, pid} <- find_pid(auction_id),
         do: GenServer.cast(pid, {:start_duration_timer, auction, pid})
  end

  def process_command(%Command{
        command: :start_decision_duration_timer,
        data: auction = %struct{id: auction_id}
      }) when is_auction(struct) do
    with {:ok, pid} <- find_pid(auction_id),
         do: GenServer.cast(pid, {:start_decision_duration_timer, auction, pid})
  end

  def process_command(%Command{command: :extend_duration, data: auction_id}) do
    with {:ok, pid} <- find_pid(auction_id),
         do: GenServer.call(pid, {:extend_duration, pid})
  end

  def should_extend?(auction_id) do
    time_remaining = AuctionTimer.read_timer(auction_id, :duration)

    case time_remaining <= @extension_time do
      true ->
        {true, @extension_time}

      _ ->
        {false, time_remaining}
    end
  end

  # Server
  def init(auction_id) do
    {:ok, %{auction_id: auction_id, duration_timer: nil, decision_duration_timer: nil}}
  end

  def handle_info(:end_auction_timer, state = %{auction_id: auction_id}) do
    auction_id
    |> Auctions.get_auction()
    |> Auctions.end_auction()

    {:noreply, state}
  end

  def handle_info(:end_auction_decision_timer, state = %{auction_id: auction_id}) do
    auction_id
    |> Auctions.get_auction()
    |> Auctions.expire_auction()

    new_state = Map.put(state, :decision_duration_timer, nil)
    {:noreply, new_state}
  end

  def handle_call({:get_timer_ref, :duration}, _from, state = %{duration_timer: nil}),
    do: {:reply, false, state}

  def handle_call({:get_timer_ref, :duration}, _from, state = %{duration_timer: timer_ref}) do
    {:reply, {:ok, timer_ref}, state}
  end

  def handle_call(
        {:get_timer_ref, :decision_duration},
        _from,
        state = %{decision_duration_timer: nil}
      ),
      do: {:reply, false, state}

  def handle_call(
        {:get_timer_ref, :decision_duration},
        _from,
        state = %{decision_duration_timer: timer_ref}
      ) do
    {:reply, {:ok, timer_ref}, state}
  end

  def handle_call({:extend_duration, _pid}, _from, state = %{duration_timer: nil}),
    do: {:reply, state, state}

  def handle_call(
        {:extend_duration, pid},
        _from,
        current_state = %{duration_timer: duration_timer}
      ) do
    new_state =
      case Process.cancel_timer(duration_timer) do
        false ->
          current_state

        _ ->
          new_timer = create_timer(pid, @extension_time, :duration)
          Map.put(current_state, :duration_timer, new_timer)
      end

    {:reply, new_state, new_state}
  end

  def handle_cast({:start_duration_timer, %struct{duration: duration}, pid}, current_state) when is_auction(struct) do
    new_timer = create_timer(pid, duration, :duration)
    new_state = Map.put(current_state, :duration_timer, new_timer)
    {:noreply, new_state}
  end

  def handle_cast(
        {:start_decision_duration_timer, %struct{decision_duration: decision_duration}, pid},
        current_state = %{duration_timer: duration_timer}
      ) when is_auction(struct) do
    if duration_timer do
      Process.cancel_timer(duration_timer)
    end

    new_timer = create_timer(pid, decision_duration, :decision_duration)

    new_state =
      current_state
      |> Map.put(:duration_timer, nil)
      |> Map.put(:decision_duration_timer, new_timer)

    {:noreply, new_state}
  end

  def handle_cast({:cancel_timer, :duration}, state = %{duration_timer: nil}),
    do: {:noreply, state}

  def handle_cast({:cancel_timer, :duration}, state = %{duration_timer: timer_ref}) do
    Process.cancel_timer(timer_ref)
    new_state = Map.put(state, :duration_timer, nil)
    {:noreply, new_state}
  end

  def handle_cast({:cancel_timer, :decision_duration}, state = %{decision_duration_timer: nil}),
    do: {:noreply, state}

  def handle_cast(
        {:cancel_timer, :decision_duration},
        state = %{decision_duration_timer: timer_ref}
      ) do
    Process.cancel_timer(timer_ref)
    new_state = Map.put(state, :decision_duration_timer, nil)
    {:noreply, new_state}
  end

  # Private
  defp get_auction_timer_name(auction_id) do
    {:via, Registry, {@registry_name, auction_id}}
  end

  defp create_timer(pid, duration, _type = :duration) do
    Process.send_after(pid, :end_auction_timer, duration)
  end

  defp create_timer(pid, duration, _type = :decision_duration) do
    Process.send_after(pid, :end_auction_decision_timer, duration)
  end
end
