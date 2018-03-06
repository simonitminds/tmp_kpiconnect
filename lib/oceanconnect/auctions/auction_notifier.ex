defmodule Oceanconnect.Auctions.AuctionNotifier do
  @task_supervisor Application.get_env(:oceanconnect, :task_supervisor) || Task.Supervisor

  def notify_participants(auction_state) do
    participants = [auction_state.buyer_id] ++ auction_state.supplier_ids
    payload = build_auction_state_payload(auction_state)

    send_notification_to_participants("user_auctions", payload, participants)
  end

  def send_notification_to_participants(channel, payload, participants) do
    {:ok, pid} = Task.Supervisor.start_link()
    @task_supervisor.async_nolink(pid, fn ->
      Enum.map(participants, fn(id) ->
        OceanconnectWeb.Endpoint.broadcast("#{channel}:#{id}", "auctions_update", payload)
      end)
    end)
  end

  def notify_updated_bid(auction, bid, _orig_bid_list, supplier_id) do
    # TODO: Add event driven setup to ensure that AuctionStore and BidList are updated before notification
    current_bid_list = Oceanconnect.Auctions.AuctionBidList.get_bid_list(auction.id)
    current_auction_state = Oceanconnect.Auctions.AuctionStore.get_current_state(auction)
    # if hd(current_bid_list).id == bid.id do
    participants = [current_auction_state.buyer_id] ++ current_auction_state.supplier_ids

    payload = current_auction_state
    |> build_auction_state_payload

    buyer_payload = payload
    |> Map.put(:bid_list, current_bid_list)

    supplier_payload = payload
    |> Map.put(:bid_list, supplier_bid_list(supplier_id, current_bid_list))

    winning_bid_ids = Enum.reduce(current_auction_state.winning_bid, [], fn(bid, acc) ->
      [bid.id | acc]
    end)
    if bid.id in winning_bid_ids do
      send_notification_to_participants("user_auctions", payload, participants)
    else
      send_notification_to_participants("user_auctions", buyer_payload, [auction.buyer_id])
      send_notification_to_participants("user_auctions", supplier_payload, [supplier_id])
    end
    # else
    #   {:error, "Bid Not Stored"}
    # end
  end

  defp build_auction_state_payload(auction_state) do
    state = Map.drop(auction_state, [:__struct__, :auction_id, :buyer_id, :supplier_ids])
    %{id: auction_state.auction_id, state: state}
  end

  defp supplier_bid_list(supplier_id, bid_list) do
    Enum.filter(bid_list, fn(bid) -> bid.supplier_id == supplier_id end)
  end
end
