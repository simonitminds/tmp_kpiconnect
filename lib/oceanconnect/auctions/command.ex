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

  def cancel_auction(auction = %Auction{}, user) do
    %Command{command: :cancel_auction, data: %{auction: auction, user: user}}
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

  def process_new_bid(bid = %AuctionBid{}, user) when not is_integer(user) do
    %Command{command: :process_new_bid, data: %{bid: bid, user: user}}
  end

  def select_winning_solution(bids, comment, user) when not is_integer(user) and is_list(bids) do
    %Command{command: :select_winning_solution, data: %{bids: bids, comment: comment, user: user}}
  end

  def submit_barge(auction_barge = %AuctionBarge{}, user) do
    %Command{command: :submit_barge, data: %{auction_barge: auction_barge, user: user}}
  end

  def unsubmit_barge(auction_barge = %AuctionBarge{}, user) do
    %Command{command: :unsubmit_barge, data: %{auction_barge: auction_barge, user: user}}
  end

  def approve_barge(auction_barge = %AuctionBarge{}, user) do
    %Command{command: :approve_barge, data: %{auction_barge: auction_barge, user: user}}
  end

  def reject_barge(auction_barge = %AuctionBarge{}, user) do
    %Command{command: :reject_barge, data: %{auction_barge: auction_barge, user: user}}
  end

  def extend_duration(auction_id) when is_integer(auction_id) do
    %Command{command: :extend_duration, data: auction_id}
  end
end
