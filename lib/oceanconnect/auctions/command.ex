defmodule Oceanconnect.Auctions.Command do
  import Oceanconnect.Auctions.Guards

  alias Oceanconnect.Auctions.{AuctionBarge, AuctionBid, AuctionComment, Solution}
  alias __MODULE__

  defstruct auction_id: nil,
            command: :get_current_state,
            data: nil

  def notify_upcoming_auction(auction = %struct{id: auction_id}, user)
      when is_auction(struct) and not is_integer(user) do
    %Command{
      auction_id: auction_id,
      command: :notify_upcoming_auction,
      data: %{auction: auction, user: user}
    }
  end

  def create_auction(auction = %struct{id: auction_id}, user)
      when is_auction(struct) and not is_integer(user) do
    %Command{
      auction_id: auction_id,
      command: :create_auction,
      data: %{auction: auction, user: user}
    }
  end

  def update_auction(auction = %struct{id: auction_id}, user)
      when is_auction(struct) and not is_integer(user) do
    %Command{
      auction_id: auction_id,
      command: :update_auction,
      data: %{auction: auction, user: user}
    }
  end

  def update_cache(auction = %struct{id: auction_id}) when is_auction(struct) do
    %Command{auction_id: auction_id, command: :update_cache, data: auction}
  end

  def reschedule_auction(auction = %struct{id: auction_id}, user) when is_auction(struct) do
    %Command{
      auction_id: auction_id,
      command: :reschedule_auction,
      data: %{auction: auction, user: user}
    }
  end

  def update_scheduled_start(auction = %struct{id: auction_id}) when is_auction(struct) do
    %Command{auction_id: auction_id, command: :update_scheduled_start, data: auction}
  end

  def cancel_scheduled_start(auction = %struct{id: auction_id}) when is_auction(struct) do
    %Command{auction_id: auction_id, command: :cancel_scheduled_start, data: auction}
  end

  def start_auction(auction = %struct{id: auction_id}, started_at, user)
      when is_auction(struct) and not is_integer(user) do
    %Command{
      auction_id: auction_id,
      command: :start_auction,
      data: %{auction: auction, started_at: started_at, user: user}
    }
  end

  def end_auction(auction = %struct{id: auction_id}, ended_at) when is_auction(struct) do
    %Command{
      auction_id: auction_id,
      command: :end_auction,
      data: %{auction: auction, ended_at: ended_at}
    }
  end

  def cancel_auction(auction = %struct{id: auction_id}, canceled_at, user)
      when is_auction(struct) do
    %Command{
      auction_id: auction_id,
      command: :cancel_auction,
      data: %{auction: auction, canceled_at: canceled_at, user: user}
    }
  end

  def finalize_auction(auction = %struct{}) when is_auction(struct) do
    %Command{auction_id: auction, command: :finalize_auction, data: auction}
  end

  def start_duration_timer(auction = %struct{id: auction_id}) when is_auction(struct) do
    %Command{auction_id: auction_id, command: :start_duration_timer, data: auction}
  end

  def start_decision_duration_timer(auction = %struct{id: auction_id}) when is_auction(struct) do
    %Command{auction_id: auction_id, command: :start_decision_duration_timer, data: auction}
  end

  def end_auction_decision_period(auction = %struct{id: auction_id}, expired_at)
      when is_auction(struct) do
    %Command{
      auction_id: auction_id,
      command: :end_auction_decision_period,
      data: %{auction: auction, expired_at: expired_at}
    }
  end

  def process_new_bid(bid = %AuctionBid{auction_id: auction_id}, user)
      when not is_integer(user) do
    %Command{auction_id: auction_id, command: :process_new_bid, data: %{bid: bid, user: user}}
  end

  def revoke_supplier_bids(auction = %struct{id: auction_id}, product, supplier_id, user)
      when is_auction(struct) and is_integer(supplier_id) and not is_integer(user) do
    %Command{
      auction_id: auction_id,
      command: :revoke_supplier_bids,
      data: %{auction: auction, product: product, supplier_id: supplier_id, user: user}
    }
  end

  def select_winning_solution(
        solution = %Solution{bids: _bids},
        auction = %struct{id: auction_id},
        closed_at,
        port_agent,
        user
      )
      when is_auction(struct) do
    %Command{
      auction_id: auction_id,
      command: :select_winning_solution,
      data: %{
        solution: solution,
        auction: auction,
        port_agent: port_agent,
        user: user,
        closed_at: closed_at
      }
    }
  end

  def submit_comment(comment = %AuctionComment{auction_id: auction_id}, user) do
    %Command{
      auction_id: auction_id,
      command: :submit_comment,
      data: %{comment: comment, user: user}
    }
  end

  def unsubmit_comment(comment = %AuctionComment{auction_id: auction_id}, user) do
    %Command{
      auction_id: auction_id,
      command: :unsubmit_comment,
      data: %{comment: comment, user: user}
    }
  end

  def submit_barge(auction_barge = %AuctionBarge{auction_id: auction_id}, user) do
    %Command{
      auction_id: auction_id,
      command: :submit_barge,
      data: %{auction_barge: auction_barge, user: user}
    }
  end

  def unsubmit_barge(auction_barge = %AuctionBarge{auction_id: auction_id}, user) do
    %Command{
      auction_id: auction_id,
      command: :unsubmit_barge,
      data: %{auction_barge: auction_barge, user: user}
    }
  end

  def approve_barge(auction_barge = %AuctionBarge{auction_id: auction_id}, user) do
    %Command{
      auction_id: auction_id,
      command: :approve_barge,
      data: %{auction_barge: auction_barge, user: user}
    }
  end

  def reject_barge(auction_barge = %AuctionBarge{auction_id: auction_id}, user) do
    %Command{
      auction_id: auction_id,
      command: :reject_barge,
      data: %{auction_barge: auction_barge, user: user}
    }
  end

  def extend_duration(auction_id) when is_integer(auction_id) do
    %Command{auction_id: auction_id, command: :extend_duration, data: auction_id}
  end
end
