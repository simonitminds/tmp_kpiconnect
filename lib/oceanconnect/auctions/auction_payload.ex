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
    bid_list = get_user_bid_list(auction_state, auction, user_id)

    produce_payload(auction, auction_state, bid_list)
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
    |> Map.put(:winning_bids, convert_to_supplier_names(auction_state.winning_bids, auction))
  end
  defp convert_winning_bids_for_user(auction_state = %AuctionState{}, %Auction{}, supplier_id) do
    winning_bids_suppliers_ids = Enum.map(auction_state.winning_bids, fn(bid) -> bid.supplier_id end)
    order = Enum.find_index(winning_bids_suppliers_ids, fn(id) -> id == supplier_id end)

    auction_state
    |> Map.put(:winning_bids, [hd(auction_state.winning_bids)])
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

  # def build_auction_payload(auction_state, user_id) when is_integer(user_id) do
  #   auction_state
  #   |> add_bid_list(user_id)
  #   |> structure_payload
  # end
  # def build_auction_payload(auction_state, user_id) do
  #   auction_state
  #   |> add_bid_list(String.to_integer(user_id))
  #   |> structure_payload
  # end
  #
  # defp add_bid_list(auction_state = %{auction_id: auction_id, buyer_id: buyer_id, status: status}, buyer_id)
  #   when status != :pending do
  #   current_bid_list = AuctionBidList.get_bid_list(auction_id)
  #   auction_state
  #   |> Map.put(:bid_list, current_bid_list)
  #   |> add_supplier_names()
  # end
  # defp add_bid_list(auction_state = %{auction_id: auction_id, status: status}, supplier_id) when status != :pending do
  #   supplier_bid_list = auction_id
  #   |> AuctionBidList.get_bid_list
  #   |> supplier_bid_list(supplier_id)
  #
  #   auction_state
  #   |> Map.put(:bid_list, supplier_bid_list)
  #   |> convert_winning_bids_for_supplier(supplier_id)
  # end
  # defp add_bid_list(auction_state, _user_id) do
  #   auction_state
  #   |> Map.put(:bid_list, [])
  # end
  #
  # def supplier_bid_list(bid_list, supplier_id) do
  #   Enum.filter(bid_list, fn(bid) -> bid.supplier_id == supplier_id end)
  # end
  #
  # defp convert_winning_bids_for_supplier(auction_state = %{winning_bids: []}, _supplier_id), do: auction_state
  # defp convert_winning_bids_for_supplier(auction_state, supplier_id) do
  #   winning_bids_suppliers_ids = Enum.map(auction_state.winning_bids, fn(bid) -> bid.supplier_id end)
  #   order = Enum.find_index(winning_bids_suppliers_ids, fn(id) -> id == supplier_id end)
  #
  #   auction_state
  #   |> Map.put(:winning_bids, [hd(auction_state.winning_bids)])
  #   |> Map.put(:winning_bids_position, order)
  # end
  #
  # defp add_supplier_names(payload) do
  #   bid_list = convert_to_supplier_names(payload.bid_list, payload.auction_id)
  #   winning_bids = convert_to_supplier_names(payload.winning_bids, payload.auction_id)
  #   payload
  #   |> Map.put(:bid_list, bid_list)
  #   |> Map.put(:winning_bids, winning_bids)
  # end
  #
  # def convert_to_supplier_names(bid_list, auction_id) do
  #   auction = Auctions.get_auction!(auction_id)
  #   Enum.map(bid_list, fn(bid) ->
  #     supplier_name = get_name_or_alias(bid.supplier_id, auction_id, auction.anonymous_bidding)
  #     bid
  #     |> Map.drop([:__struct__, :supplier_id])
  #     |> Map.put(:supplier, supplier_name)
  #   end)
  # end
  #
  # defp get_name_or_alias(supplier_id, auction_id, _anonymous_biding = true) do
  #   Auctions.get_auction_supplier(auction_id, supplier_id).alias_name
  # end
  # defp get_name_or_alias(supplier_id, _auction_id,  _anonymous_biding) do
  #   Oceanconnect.Accounts.get_company!(supplier_id).name
  # end
  #
  # defp structure_payload(auction_state = %{bid_list: bid_list}) do
  #   state = Map.drop(auction_state, [:__struct__, :auction_id, :buyer_id, :supplier_ids])
  #   %{id: auction_state.auction_id, state: Map.delete(state, :bid_list), bid_list: bid_list}
  # end
  # defp structure_payload(auction_state) do
  #   state = Map.drop(auction_state, [:__struct__, :auction_id, :buyer_id, :supplier_ids])
  #   %{id: auction_state.auction_id, state: state}
  # end


  # def maybe_update_times(auction_state = %AuctionState{status: :open, auction_id: auction_id}) do
  #   time_remaining = Process.read_timer(AuctionTimer.timer_ref(auction_id, :duration))
  #   update_times(auction_state, time_remaining)
  # end
  # def maybe_update_times(auction_state = %AuctionState{status: :decision, auction_id: auction_id}) do
  #   time_remaining = Process.read_timer(AuctionTimer.timer_ref(auction_id, :decision_duration))
  #   update_times(auction_state, time_remaining)
  # end
  # def maybe_update_times(auction_state), do: auction_state

  # defp update_times(auction_state, time_remaining) do
  #   auction_state
  #   |> Map.put(:time_remaining, time_remaining)
  #   |> Map.put(:current_server_time, DateTime.utc_now())
  # end

end
