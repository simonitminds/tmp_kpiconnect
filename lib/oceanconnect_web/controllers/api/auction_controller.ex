defmodule OceanconnectWeb.Api.AuctionController do
  use OceanconnectWeb, :controller
  import Oceanconnect.Auctions.Guards

  alias Oceanconnect.Auctions
  alias Oceanconnect.Auctions.AuctionPayload
  alias Oceanconnect.Accounts.User
  alias OceanconnectWeb.Plugs.Auth

  def index(conn, _params) do
    user = %User{company_id: company_id} = Auth.current_user(conn)

    auction_payloads =
      user
      |> Auctions.list_auctions(false)
      |> Enum.map(fn auction ->
        auction
        |> Auctions.fully_loaded()
        |> AuctionPayload.get_auction_payload!(company_id)
      end)

    render(conn, "index.json", data: auction_payloads)
  end

  def show(conn, %{"auction_id" => auction_id}) do
    with %User{company_id: company_id} <- Auth.current_user(conn),
         auction = %struct{} when is_auction(struct) <- Auctions.get_auction!(auction_id) do
      render(conn, "show.json", data: AuctionPayload.get_auction_payload!(auction, company_id))
    else
      _ ->
        conn
        |> put_status(422)
        |> render("show.json", %{success: false, message: "Invalid"})
    end
  end
end
