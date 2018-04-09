defmodule Oceanconnect.Auctions.AuctionEvent do
  defstruct type: nil, data: %{}, auction_id: nil
  alias __MODULE__

  def emit(event = %AuctionEvent{type: type, auction_id: id, data: data}) do
    Phoenix.PubSub.broadcast(:auction_pubsub, "auction:#{auction.id}", {type, data})
  end
end
