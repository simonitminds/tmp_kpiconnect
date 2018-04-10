defmodule Oceanconnect.Auctions.AuctionEvent do
  use Ecto.Schema

  embedded_schema do
    field :type
    field :data
    field :auction_id

    timestamps
  end

  alias __MODULE__

  def emit(event = %AuctionEvent{type: type, auction_id: id, data: data}) do
    Phoenix.PubSub.broadcast(:auction_pubsub, "auction:#{id}", event)
  end
end
