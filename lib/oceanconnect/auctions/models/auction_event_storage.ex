defmodule Oceanconnect.Auctions.AuctionEventStorage do
  use Ecto.Schema
  import Ecto.Query
  import Ecto.Changeset
  alias __MODULE__

  import Oceanconnect.Auctions.Guards

  alias Oceanconnect.Auctions.{
    Auction,
    TermAuction,
    AuctionStore.AuctionState,
    AuctionStore.TermAuctionState,
    Aggregate,
    FinalizedStateCache
  }

  schema "auction_events" do
    belongs_to(:auction, Auction)
    field(:event, :binary)
    field(:version, :integer, default: 2)

    timestamps()
  end

  def changeset(%AuctionEventStorage{} = storage, attrs) do
    storage
    |> cast(attrs, [:auction_id, :event, :version])
    |> validate_required([:auction_id, :event, :version])
    |> foreign_key_constraint(:auction_id)
  end

  def persist_event!(%{auction_id: auction_id} = event) do
    %AuctionEventStorage{event: event, auction_id: auction_id}
    |> persist

    {:ok, event}
  end

  def persist(event_storage = %AuctionEventStorage{event: event}) do
    persisted_storage = Map.put(event_storage, :event, :erlang.term_to_binary(event))
    {:ok, stored} = Oceanconnect.Repo.insert(persisted_storage)
    {:ok, Map.put(stored, :event, event)}
  end

  def events_by_auction(auction_id) when is_integer(auction_id) do
    query =
      from(
        storage in __MODULE__,
        where: storage.auction_id == ^auction_id and storage.version == 2,
        select: storage.event,
        order_by: [desc: :id]
      )

    query
    |> Oceanconnect.Repo.all()
    |> Enum.map(fn event -> hydrate_event(event) end)
  end

  def most_recent_state(auction = %struct{id: auction_id}) when is_auction(struct) do
    with {:ok, state} <- FinalizedStateCache.by_auction_id(auction_id) do
      state
    else
      {:error, _} ->
        events = events_by_auction(auction_id)
        state_for_events(auction, events)
    end
  end

  defp state_for_events(auction, events) do
    if snapshot = get_latest_snapshot(events) do
      snapshot_state = snapshot.data.state
      %snapshot_type{} = snapshot_state
      snapshot_type.from_state(snapshot_state)
    else
      events
      |> Enum.reverse()
      |> Enum.reduce(state_for_type(auction), fn event, state ->
        {:ok, state} = Aggregate.apply(state, event)
        state
      end)
    end
  end

  defp state_for_type(auction = %Auction{}), do: AuctionState.from_auction(auction)
  defp state_for_type(auction = %TermAuction{}), do: TermAuctionState.from_auction(auction)

  def hydrate_event(nil), do: nil

  def hydrate_event(event) do
    :erlang.binary_to_term(event)
  end

  def get_latest_snapshot(event_list) when is_list(event_list) do
    event_list
    |> Enum.filter(fn event -> event.type == :auction_state_snapshotted end)
    |> List.first()
  end

  def get_latest_snapshot(auction_id),
    do: auction_id |> events_by_auction() |> get_latest_snapshot()
end
