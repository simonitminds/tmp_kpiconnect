defmodule OceanconnectWeb.Api.AuctionBargesController do
  use OceanconnectWeb, :controller
  alias Oceanconnect.Accounts
  alias Oceanconnect.Auctions
  alias Oceanconnect.Auctions.{Auction, Barge, AuctionPayload}

  def submit(conn, %{"auction_id" => auction_id, "barge_id" => barge_id}) do
    user = OceanconnectWeb.Plugs.Auth.current_user(conn)
    supplier_id = user.company_id


    with auction = %Auction{} <- Auctions.get_auction(auction_id),
         available_barges <- Accounts.list_company_barges(supplier_id),
         {barge_id, _} <- Integer.parse(barge_id),
         barge = %Barge{} <- Enum.find(available_barges, &(&1.id == barge_id)),
         true <- barge.id in (available_barges |> Enum.map(&(&1.id)))
    do
      Auctions.submit_barge(auction, barge, supplier_id)

      auction_payload = auction
      |> Auctions.fully_loaded
      |> AuctionPayload.get_auction_payload!(supplier_id)

      conn
      |> render("submit.json", auction_payload: auction_payload)
    else
      _ ->
        conn
        |> put_status(422)
        |> render("show.json", %{success: false, message: "Invalid barge"})
    end
  end
end
