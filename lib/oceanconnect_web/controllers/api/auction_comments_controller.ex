defmodule OceanconnectWeb.Api.AuctionCommentsController do
  use OceanconnectWeb, :controller
  import Oceanconnect.Auctions.Guards

  alias Oceanconnect.Auctions
  alias Oceanconnect.Auctions.AuctionPayload

  def create(conn, %{"auction_id" => auction_id, "comment" => comment}) do
    comment_params = %{"comment" => comment}
    time_entered = DateTime.utc_now()
    user = OceanconnectWeb.Plugs.Auth.current_user(conn)
    supplier_id = user.company_id

    with auction = %struct{} when is_auction(struct) <- Auctions.get_auction(auction_id),
         true <- supplier_id in Auctions.auction_supplier_ids(auction),
         {:ok, _comment} = Auctions.submit_comment(auction, comment_params, supplier_id, time_entered, user) do

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
        |> render("show.json", %{success: false, message: "Invalid comment"})
    end
  end

  def delete(conn, %{"auction_id" => auction_id, "comment_id" => comment_id}) do
    user = OceanconnectWeb.Plugs.Auth.current_user(conn)
    supplier_id = user.company_id

    with auction = %struct{} when is_auction(struct) <- Auctions.get_auction(auction_id),
         true <- supplier_id in Auctions.auction_supplier_ids(auction),
         :ok <- Auctions.unsubmit_comment(auction, comment_id, supplier_id, user) do

      auction_payload =
        auction
        |> Auctions.fully_loaded()
        |> AuctionPayload.get_auction_payload!(supplier_id)

      render(conn, "submit.json", auction_payload: auction_payload)
    else
      {:error, message} ->
        conn
        |> put_status(422)
        |> render("show.json", %{success: false, message: message})
    end
  end
end
