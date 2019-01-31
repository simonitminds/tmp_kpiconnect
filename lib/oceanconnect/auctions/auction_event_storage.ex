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
    AuctionStore.TermAuctionState
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
  end

  def persist(event_storage = %AuctionEventStorage{event: event}) do
    persisted_storage = Map.put(event_storage, :event, :erlang.term_to_binary(event))
    {:ok, stored} = Oceanconnect.Repo.insert(persisted_storage)
    {:ok, Map.put(stored, :event, event)}
  end

  def events_by_auction(auction_id) do
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
    events = events_by_auction(auction_id)
    state_for_type(auction, events)
  end

  defp state_for_type(auction = %Auction{}, []) do
    AuctionState.from_auction(auction)
  end

  defp state_for_type(auction = %TermAuction{}, []) do
    TermAuctionState.from_auction(auction)
  end

  defp state_for_type(auction, events) do
    last_event = hd(events)
    if last_event.type in [
         :auction_updated,
         :auction_rescheduled,
         :upcoming_auction_notified,
         :auction_created,
         :duration_extended,
         :bid_placed,
         :auto_bid_placed,
         :auto_bid_triggered
       ] do
      [_last | rest] = events
      state_for_type(auction, rest)
    else
      last_event.data.state
    end
  end

  def hydrate_event(nil), do: nil

  def hydrate_event(event) do
    :erlang.binary_to_term(event)
  end
end
