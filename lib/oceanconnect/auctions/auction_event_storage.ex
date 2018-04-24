defmodule Oceanconnect.Auctions.AuctionEventStorage do
  use Ecto.Schema
  import Ecto.Query
  alias __MODULE__

  schema "auction_events" do
    belongs_to :auction, Oceanconnect.Auctions.Auction
    field :event, :binary

    timestamps()
  end


  def events_by_auction(auction_id) do
    query = from storage in __MODULE__,
      where: storage.auction_id == ^auction_id,
      select: storage.event,
      order_by: [desc: :id]
    query
    |> Oceanconnect.Repo.all
    |> Enum.map(fn(event) -> hydrate_event(event) end)
  end

  def hydrate_event(nil), do: nil
  def hydrate_event(event) do
    :erlang.binary_to_term(event)
  end

  def persist(event_storage = %AuctionEventStorage{event: event}) do
    persisted_storage = Map.put(event_storage, :event, :erlang.term_to_binary(event))
    Oceanconnect.Repo.insert(persisted_storage)
  end
end
