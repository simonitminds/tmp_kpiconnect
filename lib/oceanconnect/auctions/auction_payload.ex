defmodule Oceanconnect.Auctions.AuctionPayload do
  alias __MODULE__
  alias Oceanconnect.Auctions
  alias Oceanconnect.Auctions.{Auction, AuctionBidList, AuctionTimer}
  alias Oceanconnect.Auctions.AuctionStore.AuctionState

  defstruct time_remaining: nil,
    current_server_time: nil,
    auction: nil,
    state: nil,
    bid_list: []

  def get_auction_payload!(auction = %Auction{}, user_id) do
    fully_loaded_auction = auction
    |> maybe_remove_suppliers(user_id)
    auction_state = fully_loaded_auction
    |> Auctions.get_auction_state!
    |> convert_winning_bid_for_user(auction, user_id)
    |> convert_lowest_bids_for_user(fully_loaded_auction, user_id)
    bid_list = get_user_bid_list(auction_state, fully_loaded_auction, user_id)

    produce_payload(fully_loaded_auction, auction_state, bid_list)
  end
  def get_auction_payload!(auction = %Auction{}, user_id, auction_state = %AuctionState{}) do
    fully_loaded_auction = auction
    |> maybe_remove_suppliers(user_id)
    updated_state = auction_state
    |> convert_winning_bid_for_user(auction, user_id)
    |> convert_lowest_bids_for_user(auction, user_id)
    bid_list = get_user_bid_list(auction_state, fully_loaded_auction, user_id)

    produce_payload(fully_loaded_auction, updated_state, bid_list)
  end

  def convert_to_supplier_names(bid_list, auction = %Auction{}) do
    Enum.map(bid_list, fn(bid) ->
      supplier_name = get_name_or_alias(bid.supplier_id, auction)
      bid
      |> Map.drop([:__struct__, :supplier_id])
      |> Map.put(:supplier, supplier_name)
    end)
  end

  def supplier_bid_list(bid_list, supplier_id) do
    Enum.filter(bid_list, fn(bid) -> bid.supplier_id == supplier_id end)
  end

  defp convert_lowest_bids_for_user(auction_state = %AuctionState{lowest_bids: []}, _auction, _user_id), do: auction_state
  defp convert_lowest_bids_for_user(auction_state = %AuctionState{}, auction = %Auction{buyer_id: buyer_id}, buyer_id) do
    auction_state
    |> Map.delete(:supplier_ids)
    |> Map.put(:lowest_bids, convert_to_supplier_names(auction_state.lowest_bids, auction))
  end
  defp convert_lowest_bids_for_user(auction_state = %AuctionState{}, %Auction{}, supplier_id) do
    lowest_bids_suppliers_ids = Enum.map(auction_state.lowest_bids, fn(bid) -> bid.supplier_id end)
    order = Enum.find_index(lowest_bids_suppliers_ids, fn(id) -> id == supplier_id end)
    lowest_bid = auction_state.lowest_bids
    |> hd
    |> Map.delete(:supplier_id)

    auction_state
    |> Map.delete(:supplier_ids)
    |> Map.put(:lowest_bids, [lowest_bid])
    |> Map.put(:lowest_bids_position, order)
    |> Map.put(:multiple, length(auction_state.lowest_bids) > 1)
  end

  defp convert_winning_bid_for_user(auction_state = %AuctionState{winning_bid: nil}, _auction, _user_id), do: auction_state
  defp convert_winning_bid_for_user(auction_state = %AuctionState{winning_bid: winning_bid}, auction = %Auction{buyer_id: buyer_id}, buyer_id) do
    converted_winning_bid = [winning_bid]
    |> convert_to_supplier_names(auction)
    |> hd
    auction_state
    |> Map.put(:winning_bid, converted_winning_bid)
  end
  defp convert_winning_bid_for_user(auction_state = %AuctionState{winning_bid: winning_bid = %{supplier_id: supplier_id}}, %Auction{}, supplier_id) do
    auction_state
    |> Map.put(:winning_bid, Map.delete(winning_bid, :supplier_id))
    |> Map.put(:winner, true)
  end
  defp convert_winning_bid_for_user(auction_state = %AuctionState{}, %Auction{}, supplier_id) do
    auction_state
    |> maybe_remove_comment(supplier_id)
    |> Map.put(:winner, false)
  end
  defp convert_winning_bid_for_user(auction_state = %AuctionState{}, _auction, _user_id), do: auction_state

  defp maybe_remove_comment(auction_state = %AuctionState{lowest_bids: lowest_bids, winning_bid: winning_bid}, supplier_id) do
    case hd(lowest_bids).supplier_id == supplier_id do
      true -> Map.put(auction_state, :winning_bid, Map.delete(winning_bid, :supplier_id))
      false -> Map.put(auction_state, :winning_bid, Map.drop(winning_bid, [:comment, :supplier_id]))
    end
  end

  defp maybe_remove_suppliers(auction = %Auction{buyer_id: buyer_id}, buyer_id), do: auction
  defp maybe_remove_suppliers(auction = %Auction{}, _supplier_id) do
    Map.delete(auction, :suppliers)
  end

  defp get_name_or_alias(supplier_id, %Auction{anonymous_bidding: true, suppliers: suppliers}) do
    hd(Enum.filter(suppliers, &(&1.id == supplier_id))).alias_name
  end
  defp get_name_or_alias(supplier_id, %Auction{suppliers: suppliers}) do
    hd(Enum.filter(suppliers, &(&1.id == supplier_id))).name
  end

  defp get_user_bid_list(%AuctionState{status: status}, _auction, _user_id) when status in [:draft, :pending], do: []
  defp get_user_bid_list(%AuctionState{}, auction = %Auction{}, user_id) do
    auction.id
    |> AuctionBidList.get_bid_list
    |> transform_bid_list_for_user(auction, user_id)
  end

  defp transform_bid_list_for_user(bid_list, auction = %Auction{buyer_id: buyer_id}, buyer_id) do
    bid_list
    |> convert_to_supplier_names(auction)
  end
  defp transform_bid_list_for_user(bid_list, %Auction{}, supplier_id) do
    bid_list
    |> supplier_bid_list(supplier_id)
  end

  defp produce_payload(auction = %Auction{id: auction_id}, auction_state = %AuctionState{status: :open}, bid_list) do
    time_remaining = AuctionTimer.read_timer(auction_id, :duration)
    current_server_time = DateTime.utc_now()
    %AuctionPayload{time_remaining: time_remaining, current_server_time: current_server_time, auction: auction, state: auction_state, bid_list: bid_list}
  end
  defp produce_payload(auction = %Auction{id: auction_id}, auction_state = %AuctionState{status: :decision}, bid_list) do
    time_remaining = AuctionTimer.read_timer(auction_id, :decision_duration)
    current_server_time = DateTime.utc_now()
    %AuctionPayload{time_remaining: time_remaining, current_server_time: current_server_time, auction: auction, state: auction_state, bid_list: bid_list}
  end
  defp produce_payload(auction = %Auction{}, auction_state = %AuctionState{}, bid_list) do
    time_remaining = 0
    current_server_time = DateTime.utc_now()
    %AuctionPayload{time_remaining: time_remaining, current_server_time: current_server_time, auction: auction, state: auction_state, bid_list: bid_list}
  end
end
