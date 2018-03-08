defmodule OceanconnectWeb.Api.BidController do
  use OceanconnectWeb, :controller
  alias Oceanconnect.Auctions
  alias Oceanconnect.Auctions.{Auction, AuctionBidList, AuctionNotifier, AuctionStore, Command}

  def create(conn, %{"auction_id" => auction_id, "supplier_id" => supplier_id, "bid" => bid_params}) do
    auction_id = String.to_integer(auction_id)
    updated_bid_params = convert_amount(bid_params)
    with auction = %Auction{} <- Auctions.get_auction(auction_id),
         %{status: :open} <- AuctionStore.get_current_state(auction),
         0.0 <- (updated_bid_params["amount"] / 0.25) - Float.floor(updated_bid_params["amount"] / 0.25)
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

  defp convert_amount(bid_params = %{"amount" => amount}) do
    {float_amount, _} = Float.parse(amount)
    Map.put(bid_params, "amount", float_amount)
  end
end
