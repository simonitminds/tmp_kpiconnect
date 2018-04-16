defmodule Oceanconnect.Auctions.AuctionEventStorage do
  use Ecto.Schema
  import Ecto.Query
  alias __MODULE__

  schema "auction_events" do
    belongs_to :auction, Oceanconnect.Auctions.Auction
    embeds_one :event, Oceanconnect.Auctions.AuctionEvent

    timestamps()
  end


  def events_by_auction(auction_id) do
    query = from storage in __MODULE__,
      where: storage.auction_id == ^auction_id,
      select: storage.event
    query
    |> Oceanconnect.Repo.all
    |> Enum.sort_by(&(&1.time_entered), &>=/2)
  end

  def persist(event = %AuctionEventStorage{}) do
    Oceanconnect.Repo.insert(event)
  end
end
