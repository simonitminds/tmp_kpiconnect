defmodule Oceanconnect.Auctions.AuctionTimer do
  use GenServer
  alias Oceanconnect.{Auctions}
  alias Oceanconnect.Auctions.AuctionStore
  alias Oceanconnect.Auctions.AuctionStore.AuctionCommand

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

  def start_link({auction_id, type_duration, type}) when type in [:duration, :decision_duration] do
    GenServer.start_link(__MODULE__, {auction_id, type_duration, type}, name: get_auction_timer_name(auction_id, type))
  end

  def init({auction_id, type_duration, type}) do
    if {:ok, pid} = find_pid(auction_id, type) do
      timer = create_timer(pid, type_duration, type)
      {:ok, %{timer: timer, auction_id: auction_id, duration: type_duration}}
    end
  end

  def handle_info(:end_auction_timer, state = %{auction_id: auction_id, duration: duration}) do
    %Auctions.Auction{id: auction_id, decision_duration: duration}
    |> AuctionCommand.end_auction
    |> AuctionStore.process_command

    {:noreply, state}
  end

  def handle_info(:end_auction_decision_timer, state = %{auction_id: auction_id}) do
    %Auctions.Auction{id: auction_id}
    |> AuctionCommand.end_auction_decision_period
    |> AuctionStore.process_command

    {:noreply, state}
  end

  def handle_call(:read_timer, _from, state = %{timer: timer_ref}) do
    {:reply, timer_ref, state}
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

  # def reset_timer() do
  #   GenServer.call(__MODULE__, :reset_timer)
  # end

  # def handle_call(:reset_timer, _from, %{timer: timer}) do
  #   :timer.cancel(timer)
  #   timer = Process.send_after(self(), :work, 60_000)
  #   {:reply, :ok, %{timer: timer})
  # end
end
