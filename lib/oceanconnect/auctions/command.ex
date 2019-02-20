defmodule Oceanconnect.Auctions.Command do
  import Oceanconnect.Auctions.Guards

  alias Oceanconnect.Auctions.{AuctionBarge, AuctionBid, AuctionComment, Solution}
  alias __MODULE__

  defstruct command: :get_current_state, data: nil

  def update_auction(auction = %struct{}, user) when is_auction(struct) and not is_integer(user) do
    %Command{command: :update_auction, data: %{auction: auction, user: user}}
  end

  def update_cache(auction = %struct{}) when is_auction(struct) do
    %Command{command: :update_cache, data: auction}
  end

  def update_scheduled_start(auction = %struct{}) when is_auction(struct) do
    %Command{command: :update_scheduled_start, data: auction}
  end

  def cancel_scheduled_start(auction = %struct{}) when is_auction(struct) do
    %Command{command: :cancel_scheduled_start, data: auction}
  end

  def start_auction(auction = %struct{}, user) when is_auction(struct) and not is_integer(user) do
    %Command{command: :start_auction, data: %{auction: auction, user: user}}
  end

  def end_auction(auction = %struct{}) when is_auction(struct) do
    %Command{command: :end_auction, data: auction}
  end

  def cancel_auction(auction = %struct{}, user) when is_auction(struct) do
    %Command{command: :cancel_auction, data: %{auction: auction, user: user}}
  end

  def start_duration_timer(auction = %struct{}) when is_auction(struct) do
    %Command{command: :start_duration_timer, data: auction}
  end

  def start_decision_duration_timer(auction = %struct{}) when is_auction(struct) do
    %Command{command: :start_decision_duration_timer, data: auction}
  end

  def end_auction_decision_period(auction = %struct{}) when is_auction(struct) do
    %Command{command: :end_auction_decision_period, data: auction}
  end

  def enter_bid(bid = %AuctionBid{}) do
    %Command{command: :enter_bid, data: bid}
  end

  def process_new_bid(bid = %AuctionBid{}, user) when not is_integer(user) do
    %Command{command: :process_new_bid, data: %{bid: bid, user: user}}
  end

  def revoke_supplier_bids(auction, product, supplier_id, user)
      when is_integer(supplier_id) and not is_integer(user) do
    %Command{
      command: :revoke_supplier_bids,
      data: %{auction: auction, product: product, supplier_id: supplier_id, user: user}
    }
  end

  def select_winning_solution(solution = %Solution{bids: _bids}, auction, port_agent, user) do
    %Command{
      command: :select_winning_solution,
      data: %{solution: solution, auction: auction, port_agent: port_agent, user: user}
    }
  end

  def submit_comment(comment = %AuctionComment{}, user) do
    %Command{command: :submit_comment, data: %{comment: comment, user: user}}
  end

  def unsubmit_comment(comment = %AuctionComment{}, user) do
    %Command{
      command: :unsubmit_comment,
      data: %{comment: comment, user: user}
    }
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
