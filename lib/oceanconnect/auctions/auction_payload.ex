defmodule Oceanconnect.Auctions.AuctionPayload do
  alias __MODULE__
  alias Oceanconnect.Auctions
  alias Oceanconnect.Auctions.{Auction, AuctionBid, AuctionTimer}
  alias Oceanconnect.Auctions.AuctionStore.AuctionState

  defstruct time_remaining: nil,
            current_server_time: nil,
            auction: nil,
            status: :pending,
            winning_bid: nil,
            lowest_bids: [],
            bid_history: [],
            is_leading: false,
            lead_is_tied: false


  def get_auction_payload!(auction = %Auction{buyer_id: buyer_id}, buyer_id) do
    auction_state = Auctions.get_auction_state!(auction)
    get_buyer_auction_payload(auction, buyer_id, auction_state)
  end

  def get_auction_payload!(auction = %Auction{}, supplier_id) do
    auction_state = Auctions.get_auction_state!(auction)
    get_supplier_auction_payload(auction, supplier_id, auction_state)
  end

  def get_auction_payload!(
        auction = %Auction{buyer_id: buyer_id},
        buyer_id,
        auction_state = %AuctionState{}
      ) do
    get_buyer_auction_payload(auction, buyer_id, auction_state)
  end

  def get_auction_payload!(auction = %Auction{}, supplier_id, auction_state = %AuctionState{}) do
    get_supplier_auction_payload(auction, supplier_id, auction_state)
  end

  def get_supplier_auction_payload(auction = %Auction{}, supplier_id, state = %AuctionState{lowest_bids: lowest_bids, bids: bids, status: status, winning_bid: winning_bid}) do
    %AuctionPayload{
      time_remaining: get_time_remaining(auction, state),
      current_server_time:  DateTime.utc_now(),
      auction: scrub_auction(auction, supplier_id),
      status: status,
      lowest_bids: Enum.map(lowest_bids, &(scrub_bid_for_supplier(&1, supplier_id, auction))),
      bid_history: Enum.filter(bids, &(&1.supplier_id == supplier_id)) |> Enum.map(&(scrub_bid_for_supplier(&1, supplier_id, auction))),
      winning_bid: scrub_bid_for_supplier(winning_bid, supplier_id, auction),
      is_leading: is_leading?(state, supplier_id),
      lead_is_tied: lead_is_tied?(state)
    }
  end

  def get_buyer_auction_payload(auction = %Auction{}, buyer_id, state = %AuctionState{lowest_bids: lowest_bids, bids: bids, status: status, winning_bid: winning_bid}) do
    %AuctionPayload{
      time_remaining: get_time_remaining(auction, state),
      current_server_time:  DateTime.utc_now(),
      auction: scrub_auction(auction, buyer_id),
      status: status,
      lowest_bids: Enum.map(lowest_bids, &(scrub_bid_for_buyer(&1, buyer_id, auction))),
      bid_history: bids |> Enum.map(&(scrub_bid_for_buyer(&1, buyer_id, auction))),
      winning_bid: scrub_bid_for_buyer(winning_bid, buyer_id, auction),
      is_leading: false,
      lead_is_tied: lead_is_tied?(state)
    }
  end

  defp get_time_remaining(auction = %Auction{}, %AuctionState{status: :open}) do
    AuctionTimer.read_timer(auction.id, :duration)
  end
  defp get_time_remaining(auction = %Auction{}, %AuctionState{status: :decision}) do
    AuctionTimer.read_timer(auction.id, :decision_duration)
  end
  defp get_time_remaining(_auction = %Auction{}, %AuctionState{}), do: 0

  defp scrub_auction(auction = %Auction{buyer_id: buyer_id}, buyer_id), do: auction
  defp scrub_auction(auction = %Auction{}, _supplier_id) do
    Map.delete(auction, :suppliers)
  end

  defp scrub_bid_for_supplier(nil, _supplier_id, _auction), do: nil
  defp scrub_bid_for_supplier(bid = %AuctionBid{supplier_id: supplier_id}, supplier_id, _auction = %Auction{}) do
    %{ bid | min_amount: bid.min_amount, comment: bid.comment }
    |> Map.from_struct
  end
  defp scrub_bid_for_supplier(bid = %AuctionBid{}, _supplier_id, _auction = %Auction{}) do
    %{ bid | min_amount: nil, comment: nil }
    |> Map.from_struct
    |> Map.delete(:supplier_id)
  end

  defp scrub_bid_for_buyer(nil, _buyer_id, _auction), do: nil
  defp scrub_bid_for_buyer(bid = %AuctionBid{}, _buyer_id, auction = %Auction{}) do
    supplier = get_name_or_alias(bid.supplier_id, auction)
    %{ bid |
       supplier_id: nil,
       min_amount: nil
    }
    |> Map.from_struct
    |> Map.put(:supplier, supplier)
  end

  defp get_name_or_alias(supplier_id, %Auction{anonymous_bidding: true, suppliers: suppliers}) do
    hd(Enum.filter(suppliers, &(&1.id == supplier_id))).alias_name
  end
  defp get_name_or_alias(supplier_id, %Auction{suppliers: suppliers}) do
    hd(Enum.filter(suppliers, &(&1.id == supplier_id))).name
  end

  defp is_leading?(_state = %AuctionState{lowest_bids: []}, supplier_id), do: false
  defp is_leading?(_state = %AuctionState{lowest_bids: lowest_bids = [lowest | _]}, supplier_id) do
    lowest_bids
    |> Enum.any?(fn(bid) ->
      bid.amount == lowest.amount && bid.supplier_id == supplier_id
    end)
  end

  defp lead_is_tied?(_state = %AuctionState{lowest_bids: []}), do: false
  defp lead_is_tied?(_state = %AuctionState{lowest_bids: lowest_bids = [lowest | _]}) do
    tied_bids = lowest_bids
    |> Enum.count(fn(bid) -> bid.amount == lowest.amount end)

    tied_bids > 1
  end
end
