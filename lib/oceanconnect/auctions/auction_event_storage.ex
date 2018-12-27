defmodule Oceanconnect.Auctions.AuctionEventStorage do
  use Ecto.Schema
  import Ecto.Query
  import Ecto.Changeset
  alias __MODULE__

  schema "auction_events" do
    belongs_to(:auction, Oceanconnect.Auctions.Auction)
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

  def hydrate_event(nil), do: nil
  def hydrate_event(event) do
    :erlang.binary_to_term(event)
  end
end
