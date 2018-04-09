defmodule Oceanconnect.Auctions.AuctionTimer do
  use GenServer
  alias Oceanconnect.{Auctions}
  alias Oceanconnect.Auctions.AuctionStore
  alias Oceanconnect.Auctions.Command

  @registry_name :auction_timers_registry

  def find_pid(auction_id, type) do
    with [{pid, _}] <- Registry.lookup(@registry_name, "#{auction_id}-#{type}") do
      {:ok, pid}
    else
      [] -> {:error, "Auction Timer Not Started"}
    end
  end

  def timer_ref(auction_id, type) do
    with {:ok, pid}       <- find_pid(auction_id, type),
         {:ok, timer_ref} <- GenServer.call(pid, :read_timer),
         do: timer_ref
  end

  defp get_auction_timer_name(auction_id, type) do
    {:via, Registry, {@registry_name, "#{auction_id}-#{type}"}}
  end

  # Client
  def start_link({auction_id, type_duration, type}) when type in [:duration, :decision_duration] do
    GenServer.start_link(__MODULE__, {auction_id, type_duration, type}, name: get_auction_timer_name(auction_id, type))
  end

  def process_command(%Command{command: :extend_duration, data: %{auction_id: auction_id}}) do
    with {:ok, pid} <- find_pid(auction_id, :duration),
      do: GenServer.call(pid, {:extend_duration, pid})
  end

  # Server
  def init({auction_id, type_duration, type}) do
    if {:ok, pid} = find_pid(auction_id, type) do
      timer = create_timer(pid, type_duration, type)
      {:ok, %{timer: timer, auction_id: auction_id, duration: type_duration}}
    end
  end

  def handle_info(:end_auction_timer, state = %{auction_id: auction_id, duration: duration}) do
    %Auctions.Auction{id: auction_id, duration: duration}
    |> Command.end_auction
    |> AuctionStore.process_command

    {:noreply, state}
  end

  def handle_info(:end_auction_decision_timer, state = %{auction_id: auction_id}) do
    %Auctions.Auction{id: auction_id}
    |> Command.end_auction_decision_period
    |> AuctionStore.process_command

    {:noreply, state}
  end

  def handle_call(:read_timer, _from, state = %{timer: timer_ref}) do
    {:reply, timer_ref, state}
  end

  def handle_call({:extend_duration, pid}, _from, current_state = %{timer: timer_ref}) do
    Process.cancel_timer(timer_ref)
    new_timer = create_timer(pid, 3 * 60_000, :duration)
    new_state = Map.put(current_state, :timer, new_timer)
    {:reply, :ok, new_state}
  end

  defp create_timer(pid, duration, _type = :duration) do
    Process.send_after(pid, :end_auction_timer, duration)
  end
  defp create_timer(pid, duration, _type = :decision_duration) do
    Process.send_after(pid, :end_auction_decision_timer, duration)
  end

  # Client
  def get_timer(pid) do
    GenServer.call(pid, :read_timer)
  end

  def maybe_extend_auction(auction_id) do
    time_remaining = Process.read_timer(__MODULE__.timer_ref(auction_id, :duration))
    if time_remaining <= 3 * 60_000 do
      auction_id
      |> Command.extend_duration
      |> __MODULE__.process_command
    end
  end

  def cancel_timer(auction_id, timer_type) do
    auction_id
    |> __MODULE__.timer_ref(timer_type)
    |> Process.cancel_timer
  end
end
