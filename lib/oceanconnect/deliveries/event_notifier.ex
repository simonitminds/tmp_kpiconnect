defmodule Oceanconnect.Deliveries.EventNotifier do
  alias Oceanconnect.Deliveries
  alias Oceanconnect.Auctions.AuctionEvent

  def emit(%AuctionEvent{} = event, claim) do
    broadcast(event, claim)
    {:ok, true}
  end

  defp broadcast(event, claim) do
    :ok = Phoenix.PubSub.broadcast(:auction_pubsub, "auctions", {event, claim})
  end
end
