defmodule Oceanconnect.Auctions.AuctionPayload do
  alias __MODULE__
  alias Oceanconnect.Auctions
  alias Oceanconnect.Auctions.{Auction, AuctionBidList, AuctionTimer}
  alias Oceanconnect.Auctions.AuctionStore.AuctionState

  defstruct time_remaining: nil,
            current_server_time: nil,
            auction: nil,
            winning_bid: nil,
            lowest_bids: [],
            bids_history: [],

  def get_auction_payload!(auction = %Auction{buyer_id: buyer_id}, buyer_id) do
    auction_state = Auctions.get_auction_state!(auction)
    get_buyer_auction_payload(auction, buyer_id, auction_state)
  end

  def get_auction_payload!(auction = %Auction{buyer_id: buyer_id}, supplier_id) do
    auction_state = get_the_state(...)
    get_supplier_auction_payload(auction, supplier_id, auction_state)
  end

  def get_auction_payload!(
        auction = %Auction{buyer_id: buyer_id},
        buyer_id,
        auction_state = %AuctionState{}
      ) do
    get_buyer_auction_payload(auction, buyer_id, auction_state)
  end

  def get_auction_payload!(auction = %Auction{}, user_id, auction_state = %AuctionState{}) do
    get_supplier_auction_payload(auction, supplier_id, auction_state)
  end

  def get_supplier_auction_payload(auction = %Auction{}, supplier_id, state = %AuctionState{lowest_bids: lowest_bids, bid: bids}) do
    %AuctionPayload{
      time_remaining: AuctionTimer.read_timer(auction_id, :duration),
      current_server_time:  DateTime.utc_now(),
      auction: auction,
      lowest_bids: Enum.map(lowest_bids, &scrub_bid_for_supplier/1),
      bid_history: Enum.filter(bids, &(&.supplier_id == supplier_id))
    }
  end

  def get_buyer_auction_payload(auction = %Auction{}, buyer_id, state = %AuctionState{lowest_bids: lowest_bids, bid: bids}) do
    %AuctionPayload{
      time_remaining: AuctionTimer.read_timer(auction_id, :duration),
      current_server_time:  DateTime.utc_now(),
      auction: auction,
      lowest_bids: Enum.map(lowest_bids, &scrub_bid_for_buyer/1),
      bid_history: Enum.filter(bids, &(&.supplier_id == supplier_id))
    }

  end

  defp scrub_bid_for_supplier(bid = %AuctionBid{}, supplier_id) do
    %{ bid |
      supplier_id: bid.supplier_id == supplier_id ? supplier_id : nil,
      min_amount: bid.supplier_id == supplier_id ? bid.min_amount : nil,
      comment: bid.supplier_id == supplier_id ? bid.comment : nil
    }
  end
  defp scrub_bid_for_buyer(bid = %AuctionBid{}, supplier_id) do
    %{ bid |
       supplier: get_name_or_alias(bid.supplier_id, auction)
       supplier_id: nil,
       min_amount: nil,
    }
  end

  defp get_name_or_alias(supplier_id, %Auction{anonymous_bidding: true, suppliers: suppliers}) do
    hd(Enum.filter(suppliers, &(&1.id == supplier_id))).alias_name
  end

  defp get_name_or_alias(supplier_id, %Auction{suppliers: suppliers}) do
    hd(Enum.filter(suppliers, &(&1.id == supplier_id))).name
  end
end
