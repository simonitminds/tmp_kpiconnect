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
    payload = current_auction_state
    |> build_auction_state_payload

    buyer_payload = payload
    |> Map.put(:bid_list, current_bid_list)
    |> convert_to_supplier_names(auction)

    supplier_payload = payload
    |> Map.put(:bid_list, supplier_bid_list(supplier_id, current_bid_list))

    winning_bid_ids = Enum.reduce(current_auction_state.winning_bid, [], fn(bid, acc) ->
      [bid.id | acc]
    end)

    send_notification_to_participants("user_auctions", buyer_payload, [auction.buyer_id])
    send_notification_to_participants("user_auctions", supplier_payload, [supplier_id])
    if bid.id in winning_bid_ids do
      # TODO: Remove suppliers that declined from notification list
      auction_with_participants = Oceanconnect.Auctions.with_participants(auction)
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

  defp build_auction_state_payload(auction_state) do
    state = Map.drop(auction_state, [:__struct__, :auction_id, :buyer_id, :supplier_ids])
    %{id: auction_state.auction_id, state: state}
  end

  defp supplier_bid_list(supplier_id, bid_list) do
    Enum.filter(bid_list, fn(bid) -> bid.supplier_id == supplier_id end)
  end

  defp convert_to_supplier_names(payload, auction) do
    bid_list = Enum.map(payload.bid_list, fn(bid) ->
      supplier_name = get_name_or_alias(bid.supplier_id, auction)
      bid
      |> Map.drop([:__struct__, :supplier_id])
      |> Map.put(:supplier, supplier_name)
    end)
    winning_bid = Enum.map(payload.state.winning_bid, fn(bid) ->
      supplier_name = get_name_or_alias(bid.supplier_id, auction)
      bid
      |> Map.drop([:__struct__, :supplier_id])
      |> Map.put(:supplier, supplier_name)
    end)
    payload
    |> Map.put(:bid_list, bid_list)
    |> put_in([:state, :winning_bid], winning_bid)
  end

  defp get_name_or_alias(supplier_id, %{id: auction_id, anonymous_bidding: true}) do
    Oceanconnect.Auctions.get_auction_supplier(auction_id, supplier_id).alias_name
  end
  defp get_name_or_alias(supplier_id, _) do
    Oceanconnect.Accounts.get_company!(supplier_id).name
  end
end
