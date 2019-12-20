defmodule Oceanconnect.Auctions.AuctionNotifier do
  import Oceanconnect.Auctions.Guards

  alias Oceanconnect.Auctions
  alias Oceanconnect.Accounts
  alias Oceanconnect.Auctions.{AuctionPayload}

  @task_supervisor Application.get_env(:oceanconnect, :task_supervisor) || Task.Supervisor

  def notify_participants(state = %state_struct{auction_id: auction_id})
      when is_auction_state(state_struct) do
    auction_id
    |> Auctions.get_auction!()
    |> notify_participants(state)
  end

  def notify_participants(auction = %struct{}) when is_auction(struct) do
    auction_state = Auctions.get_auction_state!(auction)
    notify_participants(auction, auction_state)
  end

  def notify_participants(auction = %struct{}, state = %state_struct{})
      when is_auction_state(state_struct) and is_auction(struct) do
    users =
      auction
      |> Auctions.auction_participant_ids()
      |> MapSet.new()
      |> MapSet.union(admins_and_observers(auction))
      |> MapSet.to_list()

    notify_auction_users(auction, users, state)
  end

  def notify_buyer_participants(auction = %struct{buyer_id: buyer_id}) when is_auction(struct) do
    state = Auctions.get_auction_state!(auction)

    users =
      [buyer_id]
      |> MapSet.new()
      |> MapSet.union(admins_and_observers(auction))
      |> MapSet.to_list()

    notify_auction_users(auction, users, state)
  end

  def send_notification_to_participants(channel, payload, participants) do
    Task.Supervisor.async_nolink(Oceanconnect.Notifications.TaskSupervisor, fn ->
      Enum.map(participants, fn id ->
        OceanconnectWeb.Endpoint.broadcast!("#{channel}:#{id}", "auctions_update", payload)
      end)
    end)
  end

  defp admins_and_observers(auction) do
    Accounts.list_admin_users()
    |> Enum.map(& &1.id)
    |> MapSet.new()
    |> MapSet.union(MapSet.new(Auctions.auction_observer_ids(auction)))
  end

  defp notify_auction_users(auction, users, state) do
    Enum.map(users, fn user_id ->
      payload = AuctionPayload.get_auction_payload!(auction, user_id, state)
      send_notification_to_participants("user_auctions", payload, [user_id])
    end)
  end
end
