defmodule Oceanconnect.Auctions.AuctionNotifier do
  alias Oceanconnect.Auctions
  alias Oceanconnect.Accounts
  alias Oceanconnect.Auctions.{Auction, AuctionPayload, SpotAuctionState}

  @task_supervisor Application.get_env(:oceanconnect, :task_supervisor) || Task.Supervisor

  def notify_participants(%SpotAuctionState{auction_id: auction_id}) do
    auction =
      Auctions.AuctionCache.read(auction_id)
      |> Auctions.fully_loaded()

    notify_participants(auction)
  end

  def notify_participants(auction = %Auction{}) do
    participants = Auctions.auction_participant_ids(auction)

    Enum.map(participants, fn user_id ->
      payload =
        auction
        |> AuctionPayload.get_auction_payload!(user_id)

      send_notification_to_participants("user_auctions", payload, [user_id])
    end)

    notify_admin(auction)
  end

  def notify_buyer_participants(auction = %Auction{buyer_id: buyer_id}) do
    payload = AuctionPayload.get_auction_payload!(auction, buyer_id)
    send_notification_to_participants("user_auctions", payload, [buyer_id])

    notify_admin(auction)
  end

  def send_notification_to_participants(channel, payload, participants) do
    {:ok, pid} = Task.Supervisor.start_link()

    @task_supervisor.async_nolink(pid, fn ->
      Enum.map(participants, fn id ->
        OceanconnectWeb.Endpoint.broadcast("#{channel}:#{id}", "auctions_update", payload)
      end)
    end)
  end

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

  defp notify_admin(auction = %Auction{}) do
    admin_ids =
      Enum.map(Accounts.list_admin_users(), & &1.id)
      |> Enum.map(fn admin_id ->
        admin_payload =
          auction
          |> AuctionPayload.get_admin_auction_payload!()

        send_notification_to_participants("user_auctions", admin_payload, [admin_id])
      end)
  end
end
