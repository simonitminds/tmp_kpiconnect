defmodule Oceanconnect.Auctions.AuctionEventStorage do
  use Ecto.Schema
  import Ecto.Changeset

  schema "auction_events" do
    belongs_to :auction, Oceanconnect.Auctions.Auction
    field :event, {:map, Oceanconnect.Auctions.Event}
  end
end
