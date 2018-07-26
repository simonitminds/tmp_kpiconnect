defmodule Oceanconnect.Auctions.Command do
  alias Oceanconnect.Auctions.{Auction, AuctionBarge, AuctionBid}
  alias __MODULE__

  defstruct command: :get_current_state, data: nil

  def update_auction(auction = %Auction{}, user) when not is_integer(user) do
    %Command{command: :update_auction, data: %{auction: auction, user: user}}
  end

  def update_cache(auction = %Auction{}) do
    %Command{command: :update_cache, data: auction}
  end

  def update_scheduled_start(auction = %Auction{}) do
    %Command{command: :update_scheduled_start, data: auction}
  end

  def cancel_scheduled_start(auction = %Auction{}) do
    %Command{command: :cancel_scheduled_start, data: auction}
  end

  def start_auction(auction = %Auction{}, user) when not is_integer(user) do
    %Command{command: :start_auction, data: %{auction: auction, user: user}}
  end

  def end_auction(auction = %Auction{}) do
    %Command{command: :end_auction, data: auction}
  end

  def start_duration_timer(auction = %Auction{}) do
    %Command{command: :start_duration_timer, data: auction}
  end

  def start_decision_duration_timer(auction = %Auction{})  do
    %Command{command: :start_decision_duration_timer, data: auction}
  end

  def end_auction_decision_period(auction = %Auction{}) do
    %Command{command: :end_auction_decision_period, data: auction}
  end

  def enter_bid(bid = %AuctionBid{}) do
    %Command{command: :enter_bid, data: bid}
  end

  def process_new_bid(bid = %AuctionBid{}, user) when not is_integer(user) do
    %Command{command: :process_new_bid, data: %{bid: bid, user: user}}
  end

  def select_winning_bid(bid = %AuctionBid{}, user) when not is_integer(user) do
    %Command{command: :select_winning_bid, data: %{bid: bid, user: user}}
  end

  def submit_barge(auction_barge = %AuctionBarge{}) do
    %Command{command: :submit_barge, data: %{auction_barge: auction_barge}}
  end

  def approve_barge(auction_barge = %AuctionBarge{}) do
    %Command{command: :approve_barge, data: %{auction_barge: auction_barge}}
  end

  def extend_duration(auction_id) when is_integer(auction_id) do
    %Command{command: :extend_duration, data: auction_id}
  end
end
