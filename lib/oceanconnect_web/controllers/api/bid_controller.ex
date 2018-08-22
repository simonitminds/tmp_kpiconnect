defmodule OceanconnectWeb.Api.BidController do
  use OceanconnectWeb, :controller
  alias Oceanconnect.Auctions
  alias Oceanconnect.Auctions.{Auction, AuctionBid, AuctionTimer}

  def create(conn, %{"auction_id" => auction_id, "bid" => bid_params}) do
    time_entered = DateTime.utc_now()
    user = OceanconnectWeb.Plugs.Auth.current_user(conn)
    supplier_id = user.company_id
    updated_bid_params = convert_amount(bid_params)
    amount = updated_bid_params["amount"]

    with auction = %Auction{} <- Auctions.get_auction(auction_id),
         :ok <- duration_time_remaining?(auction),
         # false if amount == nil or negative
         false <- amount < 0,
         true <- quarter_increment?(amount),
         true <- supplier_id in Auctions.auction_supplier_ids(auction) do
      Auctions.place_bid(auction, updated_bid_params, supplier_id, time_entered, user)
      render(conn, "show.json", %{success: true, message: "Bid successfully placed"})
    else
      {"late_bid", message} ->
        conn
        |> put_status(409)
        |> render("show.json", %{success: false, message: message})

      _ ->
        conn
        |> put_status(422)
        |> render("show.json", %{success: false, message: "Invalid bid"})
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

  defp convert_amount(bid_params = %{"amount" => amount, "min_amount" => min_amount}) do
    bid_params
    |> Map.put("amount", convert_currency_input(amount))
    |> Map.put("min_amount", convert_currency_input(min_amount))
  end

  defp convert_amount(bid_params = %{"amount" => amount}) do
    bid_params
    |> Map.put("amount", convert_currency_input(amount))
  end

  defp convert_amount(bid_params = %{"min_amount" => min_amount}) do
    bid_params
    |> Map.put("min_amount", convert_currency_input(min_amount))
  end

  defp convert_amount(bid_params) do
    bid_params
  end

  defp convert_currency_input(""), do: nil
  defp convert_currency_input(amount) when is_float(amount), do: amount

  defp convert_currency_input(amount) do
    {float_amount, _} = Float.parse(amount)
    float_amount
  end

  defp duration_time_remaining?(auction = %Auction{id: auction_id}) do
    case AuctionTimer.read_timer(auction_id, :duration) do
      false -> maybe_pending(Auctions.get_auction_state!(auction))
      _ -> :ok
    end
  end

  defp maybe_pending(%{status: :pending}), do: :ok

  defp maybe_pending(%{status: :decision}) do
    {"late_bid", "Auction moved to decision before bid was received"}
  end

  defp maybe_pending(_), do: :error

  defp quarter_increment?(nil), do: true

  defp quarter_increment?(amount) do
    amount / 0.25 - Float.floor(amount / 0.25) == 0.0
  end
end
