defmodule Oceanconnect.Auctions.Command do
  alias Oceanconnect.Auctions.{Auction}
  alias Oceanconnect.Auctions.AuctionBidList.{AuctionBid}
  alias __MODULE__

  defstruct command: :get_current_state, data: nil

  def update_auction(auction = %Auction{}, user) do
    %Command{command: :update_auction, data: %{auction: auction, user: user}}
  end

  def update_cache(auction = %Auction{}) do
    %Command{command: :update_cache, data: auction}
  end

  def update_times(auction = %Auction{}) do
    %Command{command: :update_times, data: auction}
  end

  def start_auction(auction = %Auction{}, user) do
    %Command{command: :start_auction, data: %{auction: auction, user: user}}
  end

  def end_auction(auction = %Auction{}) do
    %Command{command: :end_auction, data: auction}
  end

  def start_duration_timer(auction_id) do
    %Command{command: :start_duration_timer, data: auction_id}
  end

  def start_decision_duration_timer(auction_id) do
    %Command{command: :start_decision_duration_timer, data: auction_id}
  end

  def end_auction_decision_period(auction = %Auction{}) do
    %Command{command: :end_auction_decision_period, data: auction}
  end

  def enter_bid(bid = %AuctionBid{}) do
    %Command{command: :enter_bid, data: bid}
  end

  def process_new_bid(bid = %AuctionBid{}, user) do
    %Command{command: :process_new_bid, data: %{bid: bid, user: user}}
  end

  def select_winning_bid(bid = %AuctionBid{}, user) do
    %Command{command: :select_winning_bid, data: %{bid: bid, user: user}}
  end

  def extend_duration(auction_id) do
    %Command{command: :extend_duration, data: auction_id}
  end
end
