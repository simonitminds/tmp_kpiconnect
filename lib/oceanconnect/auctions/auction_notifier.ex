defmodule Oceanconnect.Auctions.AuctionNotifier do
  @task_supervisor Application.get_env(:oceanconnect, :task_supervisor) || Task.Supervisor

  def notify_participants(auction_id) do
    {:ok, pid} = Task.Supervisor.start_link()
    @task_supervisor.async_nolink(pid, fn ->
      auction_with_participants = Oceanconnect.Auctions.get_auction!(auction_id)
      |> Oceanconnect.Repo.preload([:suppliers, :buyer])
      notification_state = Oceanconnect.Auctions.auction_state(%Oceanconnect.Auctions.Auction{id: auction_id})
      send_notification_to_participants(auction_with_participants, "user_auctions", notification_state)
    end)
  end

  def notify_participants(auction_id, auction_state) do
    {:ok, pid} = Task.Supervisor.start_link()
    @task_supervisor.async_nolink(pid, fn ->
      auction_with_participants = Oceanconnect.Auctions.get_auction!(auction_id)
      |> Oceanconnect.Repo.preload([:suppliers, :buyer])
      send_notification_to_participants(auction_with_participants, "user_auctions", auction_state)
    end)
  end

  def send_notification_to_participants(%{buyer: buyer, suppliers: suppliers}, channel, payload) do
    buyer_id = buyer.id
    supplier_ids = Enum.map(suppliers, fn(s) -> s.id end)
    Enum.map([buyer_id | supplier_ids], fn(id) ->
      OceanconnectWeb.Endpoint.broadcast("#{channel}:#{id}", "auctions_update", payload)
    end)
  end
end
