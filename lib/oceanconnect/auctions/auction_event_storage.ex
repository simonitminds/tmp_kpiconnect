defmodule Oceanconnect.Auctions.AuctionEventStorage do
  use Ecto.Schema
  import Ecto.Query

  schema "auction_events" do
    belongs_to :auction, Oceanconnect.Auctions.Auction
    embeds_one :event, Oceanconnect.Auctions.AuctionEvent

    timestamps()
  end


  def events_by_auction(auction_id) do
    from storage in __MODULE__,
      where: storage.auction_id == ^auction_id,
      select: storage.event
  end
end
