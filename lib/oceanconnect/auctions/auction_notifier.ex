defmodule Oceanconnect.Auctions.AuctionNotifier do
  @task_supervisor Application.get_env(:oceanconnect, :task_supervisor) || Task.Supervisor

  # def notify_participants(auction_state) do
  #   {:ok, pid} = Task.Supervisor.start_link()
  #   @task_supervisor.async_nolink(pid, fn ->
  #     notification_state = Oceanconnect.Auctions.auction_state(%Oceanconnect.Auctions.Auction{id: auction.id})
  #     send_notification_to_participants(auction, "user_auctions", notification_state)
  #   end)
  # end

  def notify_participants(auction_state) do
    {:ok, pid} = Task.Supervisor.start_link()
    @task_supervisor.async_nolink(pid, fn ->
      participants = [auction_state.buyer_id] ++ auction_state.supplier_ids
      state = Map.drop(auction_state, [:__struct__, :auction_id, :buyer_id, :supplier_ids])
      payload = %{id: auction_state.auction_id, state: state}
      send_notification_to_participants("user_auctions", payload, participants)
    end)
  end

  def send_notification_to_participants(channel, payload, participants) do
    Enum.map(participants, fn(id) ->
      OceanconnectWeb.Endpoint.broadcast("#{channel}:#{id}", "auctions_update", payload)
    end)
  end
end
