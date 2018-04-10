defmodule Oceanconnect.Auctions.AuctionEventStore do
  alias Oceanconnect.Auctions.Auction

  def event_list(%Auction{id: id}) do
    Oceanconnect.Auctions.AuctionEventStorage.events_by_auction(id)
  end
end
