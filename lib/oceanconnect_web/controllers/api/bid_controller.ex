defmodule OceanconnectWeb.Api.BidController do
  use OceanconnectWeb, :controller
  alias Oceanconnect.Auctions
  alias Oceanconnect.Auctions.{Auction, AuctionBidList}

  def create(conn, %{"auction_id" => auction_id, "bid" => bid_params}) do
    supplier_id = OceanconnectWeb.Plugs.Auth.current_user(conn).company_id
    auction_id = String.to_integer(auction_id)
    updated_bid_params = convert_amount(bid_params)
    with auction = %Auction{} <- Auctions.get_auction(auction_id),
         %{status: :open} <- Auctions.get_auction_state!(auction),
         false <- updated_bid_params["amount"] < 0,
         0.0 <- (updated_bid_params["amount"] / 0.25) - Float.floor(updated_bid_params["amount"] / 0.25),
         true <- supplier_id in Auctions.auction_supplier_ids(auction)
    do
      Auctions.place_bid(auction, updated_bid_params, supplier_id)
      render(conn, "show.json", data: %{})
    else
      _ -> conn
           |> put_status(422)
           |> render(OceanconnectWeb.ErrorView, "422.json", data: %{})
    end
  end

  def select_bid(conn, %{"auction_id" => auction_id, "bid_id" => bid_id, "comment" => comment}) do
    buyer_id = OceanconnectWeb.Plugs.Auth.current_user(conn).company_id
    auction_id = String.to_integer(auction_id)
    with auction = %Auction{} <- Auctions.get_auction(auction_id),
         true <- auction.buyer_id == buyer_id,
         %{status: :decision} <- Auctions.get_auction_state!(auction),
         bid = %AuctionBidList.AuctionBid{} <- AuctionBidList.get_bid(auction.id, bid_id)
    do
      Auctions.select_winning_bid(bid, comment)

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
