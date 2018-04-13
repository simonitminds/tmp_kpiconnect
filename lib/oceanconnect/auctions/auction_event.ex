defmodule Oceanconnect.Auctions.AuctionEvent do
  use Ecto.Schema

  embedded_schema do
    field :type, :string
    field :data, :map
    field :auction_id, :integer

    timestamps()
  end

  alias __MODULE__

  def emit(event = %AuctionEvent{type: _type, auction_id: id, data: _data}) do
    Phoenix.PubSub.broadcast(:auction_pubsub, "auction:#{id}", event)
  end
end
