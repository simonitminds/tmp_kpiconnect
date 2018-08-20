defmodule OceanconnectWeb.Api.BidController do
  use OceanconnectWeb, :controller
  alias Oceanconnect.Auctions
  alias Oceanconnect.Auctions.{Auction, AuctionBid}

  def create(conn, %{"auction_id" => auction_id, "bids" => bids_params}) do
    time_entered = DateTime.utc_now()
    user = OceanconnectWeb.Plugs.Auth.current_user(conn)
    supplier_id = user.company_id
    is_traded_bid = bid_params["is_traded_bid"] == "true"

    with  auction = %Auction{} <- Auctions.get_auction(auction_id),
          true <- supplier_id in Auctions.auction_supplier_ids(auction),
          bids <- Auctions.place_bids(auction, bids_params, supplier_id, time_entered, user),
          :ok <- validate_traded_bids(is_traded_bid, auction) do
      render(conn, "show.json", %{success: true, message: "Bids successfully placed"})
    else
      {:error, :late_bid} ->
        conn
        |> put_status(409)
        |> render("show.json", %{success: false, message: "Auction moved to decision before bid was received"})
      {"invalid_traded_bid", message} ->
        conn
        |> put_status(422)
        |> render("show.json", %{success: false, message: message})
      {:invalid_bid, bid_params} ->
        conn
        |> put_status(422)
        |> render("show.json", %{success: false, message: "Invalid bid for product #{bid_params["fuel_id"]}", bid: bid_params})
      _ ->
        conn
        |> put_status(422)
        |> render("show.json", %{success: false, message: "Invalid bid"})
    end
  end

  defp validate_traded_bids(is_traded_bid, %Auction{is_traded_bid_allowed: is_traded_bid_allowed}) do
    case (is_traded_bid && is_traded_bid_allowed) || !is_traded_bid do
      true -> :ok
      false -> {"invalid_traded_bid", "Auction not accepting traded bids"}
    end
  end

  def select_bid(conn, %{"auction_id" => auction_id, "bid_id" => bid_id, "comment" => comment}) do
    user = OceanconnectWeb.Plugs.Auth.current_user(conn)
    buyer_id = user.company_id
    auction_id = String.to_integer(auction_id)

    with auction = %Auction{} <- Auctions.get_auction(auction_id),
         true <- auction.buyer_id == buyer_id,
         %{status: :decision, active_bids: bids} <- Auctions.get_auction_state!(auction),
         bid = %AuctionBid{} <- Enum.find(bids, fn bid -> bid.id == bid_id end) do
      Auctions.select_winning_bid(bid, comment, user)

      render(conn, "show.json", %{success: true, message: ""})
    else
      _ ->
        conn
        |> put_status(422)
        |> render(OceanconnectWeb.ErrorView, "422.json", data: %{})
    end
  end
end
