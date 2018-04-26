defmodule Oceanconnect.Auctions.AuctionEvent do
  use Ecto.Schema

  defstruct id: nil,
    type: nil,
    data: nil,
    auction_id: nil,
    time_entered: nil

  alias __MODULE__

  def emit(%AuctionEvent{}, false), do: nil
  def emit(event = %AuctionEvent{type: _type, auction_id: id, data: _data}, _emit) do
    Phoenix.PubSub.broadcast(:auction_pubsub, "auction:#{id}", Map.put(event, :id, UUID.uuid4(:hex)))
  end
end
