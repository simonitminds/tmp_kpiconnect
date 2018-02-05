defmodule Oceanconnect.Auctions.AuctionTimer do
  use GenServer
  alias Oceanconnect.{Auctions}
  alias Oceanconnect.Auctions.AuctionStore
  alias Oceanconnect.Auctions.AuctionStore.AuctionCommand

  @registry_name :auction_timers_registry

  def find_pid(auction_id) do
    with [{pid, _}] <- Registry.lookup(@registry_name, auction_id) do
      {:ok, pid}
    else
      [] -> {:error, "Not Started"}
    end
  end

  def timer_ref(auction_id) do
    with {:ok, pid}       <- find_pid(auction_id),
         {:ok, timer_ref} <- GenServer.call(pid, :read_timer),
         do: timer_ref
  end

  defp get_auction_timer_name(auction_id) do
    {:via, Registry, {@registry_name, auction_id}}
  end

  def start_link(auction_id) when is_integer(auction_id) do
    GenServer.start_link(__MODULE__, auction_id, name: get_auction_timer_name(auction_id))
  end

  def init(auction_id) do
    if {:ok, pid} = find_pid(auction_id) do
      auction = Auctions.get_auction!(auction_id)
      timer = Process.send_after(pid, :end_auction_timer, auction.duration)
      {:ok, %{timer: timer, auction_id: auction_id}}
    end
  end

    def handle_info(:end_auction_timer, state = %{auction_id: auction_id}) do
    %Auctions.Auction{id: auction_id}
    |> AuctionCommand.end_auction
    |> AuctionStore.process_command(auction_id)

    {:noreply, state}
  end

  def handle_call(:read_timer, _from, state = %{timer: timer_ref}) do
    {:reply, timer_ref, state}
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
