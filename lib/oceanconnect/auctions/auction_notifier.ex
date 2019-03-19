defmodule Oceanconnect.Auctions.AuctionNotifier do
  import Oceanconnect.Auctions.Guards

  alias Oceanconnect.Auctions
  alias Oceanconnect.Accounts
  alias Oceanconnect.Auctions.{AuctionPayload}

  @task_supervisor Application.get_env(:oceanconnect, :task_supervisor) || Task.Supervisor



  def notify_participants(auction = %struct{}, state = %state_struct{}) when is_auction_state(state_struct) and is_auction(struct) do
    participants = Auctions.auction_participant_ids(auction)
    Enum.map(participants, fn user_id ->
      payload =
        auction
        |> AuctionPayload.get_auction_payload!(user_id, state)
      send_notification_to_participants("user_auctions", payload, [user_id])
    end)

    notify_admin(auction, state)
  end


  def notify_participants(state = %state_struct{auction_id: auction_id}) when is_auction_state(state_struct) do
    auction =
      Auctions.get_auction!(auction_id)

    notify_participants(auction, state)
  end

  def notify_participants(auction = %struct{}) when is_auction(struct) do
    participants = Auctions.auction_participant_ids(auction)
    Enum.map(participants, fn user_id ->
      payload =
        auction
        |> AuctionPayload.get_auction_payload!(user_id)

      send_notification_to_participants("user_auctions", payload, [user_id])
    end)

    notify_admin(auction)
  end

  def notify_buyer_participants(auction = %struct{buyer_id: buyer_id}) when is_auction(struct) do
    payload = AuctionPayload.get_auction_payload!(auction, buyer_id)
    send_notification_to_participants("user_auctions", payload, [buyer_id])

    notify_admin(auction)
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
    notify_admin(auction)

    buyer_payload =
      auction
      |> AuctionPayload.get_auction_payload!(auction.buyer_id)

    send_notification_to_participants("user_auctions", buyer_payload, [auction.buyer_id])

    Enum.map(Auctions.auction_supplier_ids(auction), fn supplier_id ->
      supplier_payload =
        auction
        |> AuctionPayload.get_auction_payload!(supplier_id)

      send_notification_to_participants("user_auctions", supplier_payload, [supplier_id])
    end)
  end

  defp notify_admin(auction = %struct{}) when is_auction(struct) do
    Enum.map(Accounts.list_admin_users(), & &1.id)
    |> Enum.map(fn admin_id ->
      admin_payload =
        auction
        |> AuctionPayload.get_admin_auction_payload!()

      send_notification_to_participants("user_auctions", admin_payload, [admin_id])
    end)
  end

  defp notify_admin(auction = %struct{}, state = %state_struct{}) when is_auction(struct) and is_auction_state(state_struct) do
    Enum.map(Accounts.list_admin_users(), & &1.id)
    |> Enum.map(fn admin_id ->
      admin_payload =
        auction
        |> AuctionPayload.get_admin_auction_payload!(state)

      send_notification_to_participants("user_auctions", admin_payload, [admin_id])
    end)
  end
end
