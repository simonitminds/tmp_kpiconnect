defmodule Oceanconnect.Auctions.Command do
  alias Oceanconnect.Auctions.{Auction}
  alias Oceanconnect.Auctions.AuctionBidList.{AuctionBid}
  alias __MODULE__

  defstruct command: :get_current_state, data: nil

  def start_auction(%Auction{id: auction_id, duration: duration}) do
    %Command{command: :start_auction, data: %{id: auction_id, duration: duration}}
  end

  def end_auction(%Auction{id: auction_id, duration: decision_duration}) do
    %Command{command: :end_auction, data: %{id: auction_id, decision_duration: decision_duration}}
  end

  def end_auction_decision_period(%Auction{id: auction_id}) do
    %Command{command: :end_auction_decision_period, data: %{id: auction_id}}
  end

  def enter_bid(bid = %AuctionBid{}) do
    %Command{command: :enter_bid, data: bid}
  end

  def process_new_bid(bid = %AuctionBid{}) do
    %Command{command: :process_new_bid, data: bid}
  end

  def select_winning_bid(bid =%AuctionBid{}) do
    %Command{command: :select_winning_bid, data: bid}
  end

  def extend_duration(auction_id) do
    %Command{command: :extend_duration, data: %{auction_id: auction_id}}
  end
end
