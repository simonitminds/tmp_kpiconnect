defmodule Oceanconnect.Auctions.Command do
  alias Oceanconnect.Auctions.{Auction}
  alias Oceanconnect.Auctions.AuctionBidList.{AuctionBid}
  alias __MODULE__

  defstruct command: :get_current_state, data: nil

  def start_auction(auction = %Auction{}) do
    %Command{command: :start_auction, data: auction}
  end

  def end_auction(auction = %Auction{}) do
    %Command{command: :end_auction, data: auction}
  end

  def start_duration_timer(auction = %Auction{}) do
    %Command{command: :start_duration_timer, data: auction}
  end

  def start_decision_duration_timer(auction = %Auction{}) do
    %Command{command: :start_decision_duration_timer, data: auction}
  end

  def end_auction_decision_period(auction = %Auction{}) do
    %Command{command: :end_auction_decision_period, data: auction}
  end

  def enter_bid(bid = %AuctionBid{}) do
    %Command{command: :enter_bid, data: bid}
  end

  def process_new_bid(bid = %AuctionBid{}) do
    %Command{command: :process_new_bid, data: bid}
  end

  def select_winning_bid(bid = %AuctionBid{}) do
    %Command{command: :select_winning_bid, data: bid}
  end

  def extend_duration(auction_id) do
    %Command{command: :extend_duration, data: %{auction_id: auction_id}}
  end
end
