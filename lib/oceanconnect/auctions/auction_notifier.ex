defmodule Oceanconnect.Auctions.AuctionNotifier do
  alias Oceanconnect.Auctions
  alias Oceanconnect.Auctions.{Auction, AuctionPayload}
  alias Oceanconnect.Auctions.AuctionStore.AuctionState

  @task_supervisor Application.get_env(:oceanconnect, :task_supervisor) || Task.Supervisor

  def notify_participants(auction_state = %AuctionState{auction_id: auction_id}) do
    auction = Auctions.AuctionCache.read(auction_id)
    participants = Auctions.auction_participant_ids(auction)
    Enum.map(participants, fn(user_id) ->
      payload = auction
      |> AuctionPayload.get_auction_payload!(user_id, auction_state)
      send_notification_to_participants("user_auctions", payload, [user_id])
    end)
  end
  def notify_participants(auction = %Auction{}) do
    participants = Auctions.auction_participant_ids(auction)
    Enum.map(participants, fn(user_id) ->
      payload = auction
      |> AuctionPayload.get_auction_payload!(user_id)
      send_notification_to_participants("user_auctions", payload, [user_id])
    end)
  end

  def send_notification_to_participants(channel, payload, participants) do
    {:ok, pid} = Task.Supervisor.start_link()
    @task_supervisor.async_nolink(pid, fn ->
      Enum.map(participants, fn(id) ->
        OceanconnectWeb.Endpoint.broadcast("#{channel}:#{id}", "auctions_update", payload)
      end)
    end)
  end

  def notify_updated_bid(auction, bid, supplier_id) do
    buyer_payload = auction
    |> AuctionPayload.get_auction_payload!(auction.buyer_id)

    supplier_payload = auction
    |> AuctionPayload.get_auction_payload!(supplier_id)

    lowest_bids_ids = Enum.reduce(buyer_payload.state.lowest_bids, [], fn(bid, acc) ->
      [bid.id | acc]
    end)

    send_notification_to_participants("user_auctions", buyer_payload, [auction.buyer_id])
    send_notification_to_participants("user_auctions", supplier_payload, [supplier_id])
    if bid.id in lowest_bids_ids do
      # TODO: Remove suppliers that declined from notification list
      rest_of_suppliers_ids = List.delete(Auctions.auction_supplier_ids(auction), supplier_id)
      Enum.map(rest_of_suppliers_ids, fn(supplier_id) ->
        supplier_payload = auction
        |> AuctionPayload.get_auction_payload!(supplier_id)
        send_notification_to_participants("user_auctions", supplier_payload, [supplier_id])
      end)
    end
  end
end
