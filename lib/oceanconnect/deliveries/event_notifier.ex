defmodule Oceanconnect.Deliveries.EventNotifier do
  import Oceanconnect.Deliveries.Guards

  alias Oceanconnect.Deliveries
  alias Oceanconnect.Deliveries.DeliveryEvent

  def emit(%DeliveryEvent{} = event, claim) do
    broadcast(event, claim)
    {:ok, true}
  end

  defp broadcast(event, claim) do
    :ok = Phoenix.PubSub.broadcast(:auction_pubsub, "auctions", {event, claim})
  end
end
