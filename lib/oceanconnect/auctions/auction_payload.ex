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
    fully_loaded_auction = Auctions.fully_loaded(auction)
    auction_state = fully_loaded_auction
    |> Auctions.get_auction_state!
    |> convert_winning_bids_for_user(fully_loaded_auction, user_id)
    bid_list = get_user_bid_list(auction_state, fully_loaded_auction, user_id)

    produce_payload(fully_loaded_auction, auction_state, bid_list)
  end
  def get_auction_payload!(auction_state = %AuctionState{auction_id: auction_id}, user_id) do
    auction = auction_id
    |> Auctions.get_auction!
    |> Auctions.fully_loaded
    updated_state = convert_winning_bids_for_user(auction_state, auction, user_id)
    bid_list = get_user_bid_list(updated_state, auction, user_id)

    produce_payload(auction, updated_state, bid_list)
  end

  def convert_to_supplier_names(bid_list, %Auction{id: auction_id, anonymous_bidding: anonymous_bidding}) do
    Enum.map(bid_list, fn(bid) ->
      supplier_name = get_name_or_alias(bid.supplier_id, auction_id, anonymous_bidding)
      bid
      |> Map.drop([:__struct__, :supplier_id])
      |> Map.put(:supplier, supplier_name)
    end)
  end

  def supplier_bid_list(bid_list, supplier_id) do
    Enum.filter(bid_list, fn(bid) -> bid.supplier_id == supplier_id end)
  end

  defp convert_winning_bids_for_user(auction_state = %AuctionState{winning_bids: []}, _auction, _user_id), do: auction_state
  defp convert_winning_bids_for_user(auction_state = %AuctionState{}, auction = %Auction{buyer_id: buyer_id}, buyer_id) do
    auction_state
    |> Map.delete(:supplier_ids)
    |> Map.put(:winning_bids, convert_to_supplier_names(auction_state.winning_bids, auction))
  end
  defp convert_winning_bids_for_user(auction_state = %AuctionState{}, %Auction{}, supplier_id) do
    winning_bids_suppliers_ids = Enum.map(auction_state.winning_bids, fn(bid) -> bid.supplier_id end)
    order = Enum.find_index(winning_bids_suppliers_ids, fn(id) -> id == supplier_id end)
    winning_bid = auction_state.winning_bids
    |> hd
    |> Map.delete(:supplier_id)

    auction_state
    |> Map.delete(:supplier_ids)
    |> Map.put(:winning_bids, [winning_bid])
    |> Map.put(:winning_bids_position, order)
  end

  defp get_name_or_alias(supplier_id, auction_id, _anonymous_biding = true) do
    Auctions.get_auction_supplier(auction_id, supplier_id).alias_name
  end
  defp get_name_or_alias(supplier_id, _auction_id,  _anonymous_biding) do
    Oceanconnect.Accounts.get_company!(supplier_id).name
  end

  defp get_user_bid_list(%AuctionState{status: :pending}, _auction, _user_id), do: []
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
    time_remaining = Process.read_timer(AuctionTimer.timer_ref(auction_id, :duration))
    current_server_time = DateTime.utc_now()
    %AuctionPayload{time_remaining: time_remaining, current_server_time: current_server_time, auction: auction, state: auction_state, bid_list: bid_list}
  end
  defp produce_payload(auction = %Auction{id: auction_id}, auction_state = %AuctionState{status: :decision}, bid_list) do
    time_remaining = Process.read_timer(AuctionTimer.timer_ref(auction_id, :decision_duration))
    current_server_time = DateTime.utc_now()
    %AuctionPayload{time_remaining: time_remaining, current_server_time: current_server_time, auction: auction, state: auction_state, bid_list: bid_list}
  end
  defp produce_payload(auction = %Auction{}, auction_state = %AuctionState{}, bid_list) do
    time_remaining = 0
    current_server_time = DateTime.utc_now()
    %AuctionPayload{time_remaining: time_remaining, current_server_time: current_server_time, auction: auction, state: auction_state, bid_list: bid_list}
  end
end
