defmodule OceanconnectWeb.Api.BidController do
  use OceanconnectWeb, :controller
  alias Oceanconnect.Auctions
  alias Oceanconnect.Auctions.{Auction}

  def create(conn, params = %{"auction_id" => auction_id, "bids" => bids_params}) do
    time_entered = DateTime.utc_now()
    user = OceanconnectWeb.Plugs.Auth.current_user(conn)
    supplier_id = user.company_id
    is_traded_bid = Map.get(params, "is_traded_bid", false) == true

    bids_params = bids_params
    |> Enum.reduce(%{}, fn({product_id, bid_params}, acc) ->
      updated_bid_params = Map.put(bid_params, "is_traded_bid", is_traded_bid)
      Map.put(acc, product_id, updated_bid_params)
    end)

    with  auction = %Auction{} <- Auctions.get_auction(auction_id),
          true <- supplier_id in Auctions.auction_supplier_ids(auction),
          :ok <- validate_traded_bids(is_traded_bid, auction),
          {:ok, _bids} <- Auctions.place_bids(auction, bids_params, supplier_id, time_entered, user) do
      render(conn, "show.json", %{success: true, message: "Bids successfully placed"})
    else
      {:error, :late_bid} ->
        conn
        |> put_status(409)
        |> render("show.json", %{success: false, message: "Auction moved to decision before bid was received"})
      {:invalid_traded_bid, message} ->
        conn
        |> put_status(422)
        |> render("show.json", %{success: false, message: message})
      {:invalid_bid, bid_params} ->
        conn
        |> put_status(422)
        |> render("show.json", %{success: false, message: "Invalid bid", bid: bid_params})
      _ ->
        conn
        |> put_status(422)
        |> render("show.json", %{success: false, message: "Invalid bid"})
    end
  end

  def revoke(conn, %{"auction_id" => auction_id, "product" => product_id}) do
    user = OceanconnectWeb.Plugs.Auth.current_user(conn)
    supplier_id = user.company_id

    with  auction = %Auction{} <- Auctions.get_auction(auction_id),
          true <- supplier_id in Auctions.auction_supplier_ids(auction),
          :ok <- Auctions.revoke_supplier_bids_for_product(auction, product_id, supplier_id, user) do
      render(conn, "show.json", %{success: true, message: "Bid successfully revoked"})
    else
      {:error, :late_bid} ->
        conn
        |> put_status(409)
        |> render("show.json", %{success: false, message: "Auction moved to decision before request was received"})
      {:error, message} ->
        conn
        |> put_status(422)
        |> render("show.json", %{success: false, message: message})
      _ ->
        conn
        |> put_status(422)
        |> render("show.json", %{success: false, message: "Invalid product"})
    end
  end

  def select_solution(conn, %{"auction_id" => auction_id, "bid_ids" => bid_ids, "comment" => comment}) do
    user = OceanconnectWeb.Plugs.Auth.current_user(conn)
    buyer_id = user.company_id
    auction_id = String.to_integer(auction_id)

    with auction = %Auction{} <- Auctions.get_auction(auction_id) |> Auctions.fully_loaded,
         true <- auction.buyer_id == buyer_id,
         state = %{status: :decision, product_bids: product_bids} <- Auctions.get_auction_state!(auction),
         selected_bids <- Auctions.bids_for_bid_ids(bid_ids, state) do
      Auctions.select_winning_solution(selected_bids, product_bids, auction, comment, user)
      render(conn, "show.json", %{success: true, message: ""})
    else
      _ ->
        conn
        |> put_status(422)
        |> render(OceanconnectWeb.ErrorView, "422.json", data: %{})
    end
  end


  defp validate_traded_bids(is_traded_bid, %Auction{is_traded_bid_allowed: is_traded_bid_allowed}) do
    case (is_traded_bid && is_traded_bid_allowed) || !is_traded_bid do
      true -> :ok
      false -> {:invalid_traded_bid, "Auction not accepting traded bids"}
    end
  end
end
