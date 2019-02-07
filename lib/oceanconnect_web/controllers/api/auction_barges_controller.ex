defmodule OceanconnectWeb.Api.AuctionBargesController do
  use OceanconnectWeb, :controller
  import Oceanconnect.Auctions.Guards

  alias Oceanconnect.Accounts
  alias Oceanconnect.Auctions
  alias Oceanconnect.Auctions.{Barge, AuctionPayload}

  def submit(conn, %{"auction_id" => auction_id, "barge_id" => barge_id}) do
    user = OceanconnectWeb.Plugs.Auth.current_user(conn)
    supplier_id = user.company_id

    with auction = %struct{} when is_auction(struct) <- Auctions.get_auction(auction_id),
         available_barges <- Accounts.list_company_barges(supplier_id),
         {barge_id, _} <- Integer.parse(barge_id),
         barge = %Barge{} <- Enum.find(available_barges, &(&1.id == barge_id)) do
      Auctions.submit_barge(auction, barge, supplier_id, user)

      auction_payload =
        auction
        |> Auctions.fully_loaded()
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

  def unsubmit(conn, %{"auction_id" => auction_id, "barge_id" => barge_id}) do
    user = OceanconnectWeb.Plugs.Auth.current_user(conn)
    supplier_id = user.company_id

    with auction = %struct{} when is_auction(struct) <- Auctions.get_auction(auction_id),
         available_barges <- Accounts.list_company_barges(supplier_id),
         {barge_id, _} <- Integer.parse(barge_id),
         barge = %Barge{} <- Enum.find(available_barges, &(&1.id == barge_id)) do
      Auctions.unsubmit_barge(auction, barge, supplier_id, user)

      auction_payload =
        auction
        |> Auctions.fully_loaded()
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

  def approve(conn, %{
        "auction_id" => auction_id,
        "barge_id" => barge_id,
        "supplier_id" => supplier_id
      }) do
    user = OceanconnectWeb.Plugs.Auth.current_user(conn)
    buyer_id = user.company_id

    with auction = %struct{} when is_auction(struct) <- Auctions.get_auction(auction_id),
         true <- buyer_id == auction.buyer_id,
         {barge_id, _} <- Integer.parse(barge_id),
         barge <- Auctions.get_barge(barge_id) do
      Auctions.approve_barge(auction, barge, supplier_id, user)

      auction_payload =
        auction
        |> Auctions.fully_loaded()
        |> AuctionPayload.get_auction_payload!(buyer_id)

      conn
      |> render("submit.json", auction_payload: auction_payload)
    else
      _ ->
        conn
        |> put_status(422)
        |> render("show.json", %{success: false, message: "Suppliers cannot approve barges"})
    end
  end

  def reject(conn, %{
        "auction_id" => auction_id,
        "barge_id" => barge_id,
        "supplier_id" => supplier_id
      }) do
    user = OceanconnectWeb.Plugs.Auth.current_user(conn)
    buyer_id = user.company_id

    with auction = %struct{} when is_auction(struct) <- Auctions.get_auction(auction_id),
         true <- buyer_id == auction.buyer_id,
         {barge_id, _} <- Integer.parse(barge_id),
         barge <- Auctions.get_barge(barge_id) do
      Auctions.reject_barge(auction, barge, supplier_id, user)

      auction_payload =
        auction
        |> Auctions.fully_loaded()
        |> AuctionPayload.get_auction_payload!(buyer_id)

      conn
      |> render("submit.json", auction_payload: auction_payload)
    else
      _ ->
        conn
        |> put_status(422)
        |> render("show.json", %{success: false, message: "Suppliers cannot reject barges"})
    end
  end
end
