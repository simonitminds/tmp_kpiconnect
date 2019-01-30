defmodule Oceanconnect.Auctions.Payloads.ProductBidsPayload do
  import Oceanconnect.Auctions.Guards

  alias Oceanconnect.Auctions.{AuctionBid, AuctionSuppliers, ProductBidState}

  defstruct lowest_bids: [],
            bid_history: [],
            is_leading: false,
            lead_is_tied: false

  def get_product_bids_payload!(state = %ProductBidState{lowest_bids: lowest_bids, bids: bids},
        auction: auction,
        buyer: buyer_id
      ) do
    %{
      lowest_bids: Enum.map(lowest_bids, &scrub_bid_for_buyer(&1, buyer_id, auction)),
      bid_history: bids |> Enum.map(&scrub_bid_for_buyer(&1, buyer_id, auction)),
      is_leading: false,
      lead_is_tied: lead_is_tied?(state)
    }
  end

  def get_product_bids_payload!(state = %ProductBidState{lowest_bids: lowest_bids, bids: bids},
        auction: auction,
        supplier: supplier_id
      ) do
    %{
      lowest_bids: Enum.map(lowest_bids, &scrub_bid_for_supplier(&1, supplier_id, auction)),
      bid_history:
        Enum.filter(bids, &(&1.supplier_id == supplier_id))
        |> Enum.map(&scrub_bid_for_supplier(&1, supplier_id, auction)),
      is_leading: is_leading?(state, supplier_id),
      lead_is_tied: lead_is_tied?(state)
    }
  end

  defp scrub_bid_for_supplier(nil, _supplier_id, _auction), do: nil

  defp scrub_bid_for_supplier(
         bid = %AuctionBid{supplier_id: supplier_id},
         supplier_id,
         _auction = %struct{}
       ) when is_auction(struct) do
    %{bid | min_amount: bid.min_amount, comment: bid.comment}
    |> Map.from_struct()
  end

  defp scrub_bid_for_supplier(bid = %AuctionBid{}, _supplier_id, _auction = %struct{}) when is_auction(struct) do
    %{bid | min_amount: nil, comment: nil, is_traded_bid: false}
    |> Map.from_struct()
    |> Map.delete(:supplier_id)
  end

  defp scrub_bid_for_buyer(nil, _buyer_id, _auction), do: nil

  defp scrub_bid_for_buyer(bid = %AuctionBid{}, _buyer_id, auction = %struct{}) when is_auction(struct) do
    supplier = AuctionSuppliers.get_name_or_alias(bid.supplier_id, auction)

    %{bid | supplier_id: nil, min_amount: nil}
    |> Map.from_struct()
    |> Map.put(:supplier, supplier)
  end

  defp is_leading?(_state = %ProductBidState{lowest_bids: []}, _supplier_id), do: false

  defp is_leading?(
         _state = %ProductBidState{lowest_bids: lowest_bids = [lowest | _]},
         supplier_id
       ) do
    lowest_bids
    |> Enum.any?(fn bid ->
      bid.amount == lowest.amount && bid.supplier_id == supplier_id
    end)
  end

  defp lead_is_tied?(_state = %ProductBidState{lowest_bids: []}), do: false

  defp lead_is_tied?(_state = %ProductBidState{lowest_bids: lowest_bids = [lowest | _]}) do
    tied_bids =
      lowest_bids
      |> Enum.count(fn bid -> bid.amount == lowest.amount end)

    tied_bids > 1
  end
end
