defmodule Oceanconnect.Auctions.AuctionNotifier do
  @task_supervisor Application.get_env(:oceanconnect, :task_supervisor) || Task.Supervisor

  def notify_participants(auction) do
    {:ok, pid} = Task.Supervisor.start_link()
    @task_supervisor.async_nolink(pid, fn ->
      notification_state = Oceanconnect.Auctions.auction_state(%Oceanconnect.Auctions.Auction{id: auction.id})
      send_notification_to_participants(auction, "user_auctions", notification_state)
    end)
  end

  def notify_participants(auction, auction_state) do
    {:ok, pid} = Task.Supervisor.start_link()
    @task_supervisor.async_nolink(pid, fn ->
      send_notification_to_participants(auction, "user_auctions", auction_state)
    end)
  end

  def send_notification_to_participants(%{buyer_id: buyer_id, supplier_ids: supplier_ids}, channel, payload) do
    Enum.map([buyer_id | supplier_ids], fn(id) ->
      OceanconnectWeb.Endpoint.broadcast("#{channel}:#{id}", "auctions_update", payload)
    end)
  end
end
