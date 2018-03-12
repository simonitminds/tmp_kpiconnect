defmodule Oceanconnect.Auctions.AuctionNotifier do
  alias Oceanconnect.Auctions

  @task_supervisor Application.get_env(:oceanconnect, :task_supervisor) || Task.Supervisor

  def notify_participants(auction_state) do
    participants = [auction_state.buyer_id] ++ auction_state.supplier_ids
    payload = Auctions.build_auction_state_payload(auction_state, nil)

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
    current_auction_state = Auctions.get_auction_state(auction)
    # if hd(current_bid_list).id == bid.id do
    auction_with_participants = Auctions.with_participants(auction)

    buyer_payload = current_auction_state
    |> Auctions.build_auction_state_payload(auction_with_participants.buyer_id)

    supplier_payload = current_auction_state
    |> Auctions.build_auction_state_payload(supplier_id)

    winning_bid_ids = Enum.reduce(current_auction_state.winning_bid, [], fn(bid, acc) ->
      [bid.id | acc]
    end)

    send_notification_to_participants("user_auctions", buyer_payload, [auction_with_participants.buyer_id])
    send_notification_to_participants("user_auctions", supplier_payload, [supplier_id])
    if bid.id in winning_bid_ids do
      # TODO: Remove suppliers that declined from notification list
      payload = current_auction_state
      |> Auctions.build_auction_state_payload(nil)

      rest_of_suppliers = auction_with_participants.suppliers
      |> Enum.filter(fn(supplier) ->
        supplier.id != supplier_id
      end)
      |> Enum.map(&(&1.id))

      send_notification_to_participants("user_auctions", payload, rest_of_suppliers)
    end
    # else
    #   {:error, "Bid Not Stored"}
    # end
  end
end
