defmodule Oceanconnect.Auctions.AuctionEvent do
  use Ecto.Schema

  embedded_schema do
    field :type, :string
    field :data, :map
    field :auction_id, :integer
    field :time_entered, :utc_datetime
  end

  alias __MODULE__

  def emit(%AuctionEvent{}, false), do: nil
  def emit(event = %AuctionEvent{type: _type, auction_id: id, data: _data}, _emit) do
    Phoenix.PubSub.broadcast(:auction_pubsub, "auction:#{id}", event)
  end
end
