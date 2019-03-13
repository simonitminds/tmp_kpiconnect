defmodule Oceanconnect.Auctions.AuctionStore do
  use GenServer
  import Oceanconnect.Auctions.Guards

  alias Oceanconnect.Auctions

  alias Oceanconnect.Auctions.{
    Aggregate,
    Auction,
    TermAuction,
    AuctionCache,
    AuctionEventStore,
    Aggregate,
    Command,
    EventNotifier,
    Solution,
    AuctionStore.AuctionState,
    AuctionStore.TermAuctionState,
    AuctionEmailNotifier
  }

  @registry_name :auctions_registry

  def find_pid(auction_id) do
    with [{pid, _}] <- Registry.lookup(@registry_name, auction_id) do
      {:ok, pid}
    else
      [] -> {:error, "Auction Store Not Started"}
    end
  end

  defp get_auction_store_name(auction_id) do
    {:via, Registry, {@registry_name, auction_id}}
  end

  # Client
  def start_link(auction = %struct{id: auction_id}) when is_auction(struct) do
    GenServer.start_link(__MODULE__, auction, name: get_auction_store_name(auction_id))
  end

  def get_current_state(%struct{id: auction_id}) when is_auction(struct) do
    with {:ok, pid} <- find_pid(auction_id),
         do: GenServer.call(pid, :get_current_state)
  end
  def get_current_state(auction_id) when is_integer(auction_id) do
    with {:ok, pid} <- find_pid(auction_id),
         do: GenServer.call(pid, :get_current_state)
  end

  def process_command(command = %Command{
        command: :select_winning_solution,
        data: %{solution: solution = %Solution{auction_id: auction_id}, auction: auction, port_agent: port_agent, user: user}
      }) do
    with {:ok, pid} <- find_pid(auction_id) do
      GenServer.call(pid, {:process, command})
    else
      {:error, msg} ->
      if %{is_admin: true} = user do
        closed_at = DateTime.utc_now()
        current_state = Auctions.get_auction_state!(auction)
        new_state = [
          Command.select_winning_solution(solution, auction, closed_at, port_agent, user)
        ] |> Enum.reduce(current_state, fn(command, state) ->
          {:ok, events} = Aggregate.process(state, command)
          persist_and_apply(events, state)
        end)

        #TODO: This should be picked up by a reaction on the notifier
        active_participants = Auctions.active_participants(auction_id)
        AuctionEmailNotifier.notify_auction_completed(
          solution.bids,
          current_state.submitted_barges,
          auction_id,
          active_participants
        )
        {:ok, new_state}
      else
        {:error, msg}
      end
    end
  end

  def process_command(command = %Command{auction_id: auction_id}) do
    with {:ok, pid} <- find_pid(auction_id),
         do: GenServer.call(pid, {:process, command})
  end

  # Server
  def init(auction = %Auction{id: auction_id}) do
    AuctionCache.make_cache_available(auction_id)
    state =
      AuctionState.from_auction(auction)
      |> replay_events(auction)

    {:ok, state}
  end

  def init(auction = %TermAuction{id: auction_id}) do
    AuctionCache.make_cache_available(auction_id)
    state =
      TermAuctionState.from_auction(auction)
      |> replay_events(auction)

    {:ok, state}
  end

  def handle_call(:get_current_state, _from, current_state) do
    {:reply, current_state, current_state}
  end

  def handle_call({:process, command = %Command{}}, _from, current_state) do
    with {:ok, events} <- Aggregate.process(current_state, command) do
      {:reply, {:ok, :command_accepted}, current_state, {:continue, events}}
    else
      {:error, message} ->
        {:reply, {:error, message}, current_state}
    end
  end

  def handle_continue(events, current_state) do
    new_state = persist_and_apply(events, current_state)
    {:noreply, new_state}
  end

  defp persist_and_apply(events, current_state) do
    events
    |> Enum.map(&AuctionEventStore.persist/1)

    Enum.reduce(events, current_state, fn(event, state) ->
      {:ok, state} = Aggregate.apply(state, event)
      {:ok, _notified} = EventNotifier.emit(state, event)
      state
    end)
  end

  defp replay_events(initial_state = %state_struct{}, %struct{id: auction_id}) when is_auction_state(state_struct) and is_auction(struct) do
    auction_id
    |> AuctionEventStore.event_list()
    |> Enum.reverse()
    |> Enum.reduce(initial_state, fn(event, state) ->
      {:ok, state} = Aggregate.apply(state, event)
      {:ok, _notified} = EventNotifier.emit(state, event)
      state
    end)
  end
end
