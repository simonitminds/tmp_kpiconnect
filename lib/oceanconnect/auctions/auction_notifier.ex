defmodule Oceanconnect.Auctions.AuctionNotifier do
  import Oceanconnect.Auctions.Guards

  alias Oceanconnect.Auctions
  alias Oceanconnect.Accounts
  alias Oceanconnect.Auctions.{AuctionPayload}

  @task_supervisor Application.get_env(:oceanconnect, :task_supervisor) || Task.Supervisor

  def notify_participants(state = %state_struct{auction_id: auction_id})
      when is_auction_state(state_struct) do
    auction = Auctions.get_auction!(auction_id)
    notify_participants(auction, state)
  end

  def notify_participants(auction = %struct{}) when is_auction(struct) do
    participants = Auctions.auction_participant_ids(auction)
    notify_auction_participants(auction, participants)
    notify_admin(auction)
    notify_observers(auction)
  end

  def notify_participants(auction = %struct{}, state = %state_struct{})
      when is_auction_state(state_struct) and is_auction(struct) do
    participants = Auctions.auction_participant_ids(auction)
    notify_auction_participants(auction, participants)
    notify_admin(auction, state)
    notify_observers(auction)
  end

  def notify_buyer_participants(auction = %struct{buyer_id: buyer_id}) when is_auction(struct) do
    payload = AuctionPayload.get_auction_payload!(auction, buyer_id)
    send_notification_to_participants("user_auctions", payload, [buyer_id])
    notify_admin(auction)
    notify_observers(auction)
  end

  def send_notification_to_participants(channel, payload, participants) do
    Task.Supervisor.async_nolink(Oceanconnect.Notifications.TaskSupervisor, fn ->
      Enum.map(participants, fn id ->
        OceanconnectWeb.Endpoint.broadcast!("#{channel}:#{id}", "auctions_update", payload)
      end)
    end)
  end

  # TODO move to new style of passing in auction state
  def notify_updated_bid(auction, _bid, _supplier_id) do
    participants = Auctions.auction_participant_ids(auction)
    notify_auction_participants(auction, participants)
    notify_admin(auction)
    notify_observers(auction)
  end

  defp notify_admin(auction = %struct{}) when is_auction(struct) do
    Accounts.list_admin_users()
    |> Enum.map(& &1.id)
    |> Enum.map(fn admin_id ->
      admin_payload = AuctionPayload.get_admin_auction_payload!(auction)
      send_notification_to_participants("user_auctions", admin_payload, [admin_id])
    end)
  end

  defp notify_admin(auction = %struct{}, state = %state_struct{})
       when is_auction(struct) and is_auction_state(state_struct) do
    Accounts.list_admin_users()
    |> Enum.map(& &1.id)
    |> Enum.map(fn admin_id ->
      admin_payload = AuctionPayload.get_admin_auction_payload!(auction, state)
      send_notification_to_participants("user_auctions", admin_payload, [admin_id])
    end)
  end

  defp notify_observers(auction) do
    Enum.map(Auctions.auction_observer_ids(auction), fn observer_id ->
      observer_payload = AuctionPayload.get_observer_auction_payload!(auction)
      send_notification_to_participants("user_auctions", observer_payload, [observer_id])
    end)
  end

  defp notify_auction_participants(auction, participants) do
    Enum.map(participants, fn user_id ->
      payload = AuctionPayload.get_auction_payload!(auction, user_id)
      send_notification_to_participants("user_auctions", payload, [user_id])
    end)
  end
end
