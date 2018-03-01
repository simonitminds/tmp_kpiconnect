defmodule OceanconnectWeb.Api.BidController do
  use OceanconnectWeb, :controller
  alias Oceanconnect.Auctions
  alias Oceanconnect.Auctions.{AuctionStore, Auction}

  def create(conn, params = %{"auction_id" => auction_id}) do
    with auction = %Auction{} <- Auctions.get_auction(auction_id),
         %{status: :open} <- AuctionStore.get_current_state(auction)
    do
      render(conn, "show.json", data: %{})
    else
      _ -> conn
           |> put_status(422)
           |> render(OceanconnectWeb.ErrorView, "422.json", data: %{})
    end
  end
end
