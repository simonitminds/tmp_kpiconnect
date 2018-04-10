defmodule Oceanconnect.Auctions.AuctionEventStorage do
  use Ecto.Schema
  import Ecto.Changeset

  schema "auction_events" do
    belongs_to :auction, Oceanconnect.Auctions.Auction
    field :event, {:map, Oceanconnect.Auctions.Event}
  end


  def events_by_auction(auction_id) do
    Oceanconnect.Repo.get_by(__MODULE__, %{auction_id: auction_id})
  end
end
