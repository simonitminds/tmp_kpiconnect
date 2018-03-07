defmodule OceanconnectWeb.Api.BidController do
  use OceanconnectWeb, :controller
  alias Oceanconnect.Auctions
  alias Oceanconnect.Auctions.{Auction, AuctionBidList, AuctionNotifier, AuctionStore, Command}

  def create(conn, params = %{"auction_id" => auction_id, "supplier_id" => supplier_id, "bid" => bid_params}) do
    auction_id = String.to_integer(auction_id)
    with auction = %Auction{} <- Auctions.get_auction(auction_id),
         %{status: :open} <- AuctionStore.get_current_state(auction)
    do
      orig_bid_list = AuctionBidList.get_bid_list(auction_id)
      supplier_id = String.to_integer(supplier_id)

      bid = bid_params
      |> Map.put("supplier_id", supplier_id)
      |> AuctionBidList.AuctionBid.from_params_to_auction_bid(auction)

      bid
      |> Command.enter_bid
      |> AuctionBidList.process_command

      bid
      |> Command.process_new_bid
      |> AuctionStore.process_command

      AuctionNotifier.notify_updated_bid(auction, bid, orig_bid_list, supplier_id)

      render(conn, "show.json", data: %{})
    else
      _ -> conn
           |> put_status(422)
           |> render(OceanconnectWeb.ErrorView, "422.json", data: %{})
    end
  end
end
