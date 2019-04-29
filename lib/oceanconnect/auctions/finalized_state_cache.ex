defmodule Oceanconnect.Auctions.FinalizedStateCache do
  use GenServer
  import Oceanconnect.Auctions.Guards
  alias Oceanconnect.Auctions
  alias Oceanconnect.Auctions.{AuctionEventStorage}

  # Server
  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def start_link do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(%{}) do
    :ets.new(:finalized_state_cache, [:set, :protected, :named_table])
    Process.send_after(self(), :populate_finalized_auction_cache, 500)
    {:ok, %{}}
  end

  def handle_info(:populate_finalized_auction_cache, _) do
    new_state =
      Auctions.list_auctions()
      |> Enum.each(fn auction = %{id: auction_id} ->
        state = %{status: status} = AuctionEventStorage.most_recent_state(auction)

        if status in [:expired, :canceled, :closed] do
          add_entry_to_cache(auction_id, state)
        end
      end)

    {:noreply, new_state}
  end

  def handle_call({:add_auction, auction_id, state}, _from, current_state) do
    result = add_entry_to_cache(auction_id, state)
    {:reply, result, current_state}
  end

  def add_auction(
        %auction_struct{id: auction_id},
        state = %state_struct{status: status}
      )
      when is_auction(auction_struct) and is_auction_state(state_struct) and
             status in [:closed, :cancelled, :expired] do
    try do
      GenServer.call(__MODULE__, {:add_auction, auction_id, state})
    catch
      :exit, _ -> {:error, "Finalized State Cache Not Started"}
    end
  end

  def add_auction(_auction, _state), do: {:error, "Cannot Add Non Finalized Auction"}

  def by_auction_id(auction_id) do
    case :ets.lookup(:finalized_state_cache, auction_id) do
      [{^auction_id, state}] -> {:ok, state}
      _ -> {:error, "No Entry for Auction"}
    end
  end

  def for_auction(%auction_struct{id: auction_id}) when is_auction(auction_struct) do
    case :ets.lookup(:finalized_state_cache, auction_id) do
      [{^auction_id, state}] -> {:ok, state}
      _ -> {:error, "No Entry for Auction"}
    end
  end

  def stop(reason \\ :normal, timeout \\ :infinity) do
    GenServer.stop(__MODULE__, reason, timeout)
  end

  defp add_entry_to_cache(auction_id, state),
    do: :ets.insert(:finalized_state_cache, {auction_id, state})
end
