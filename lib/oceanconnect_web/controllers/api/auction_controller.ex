defmodule OceanconnectWeb.Api.AuctionController do
  use OceanconnectWeb, :controller
  alias Oceanconnect.Auctions
  alias Oceanconnect.Auctions.AuctionPayload
  alias Oceanconnect.Accounts.User
  alias OceanconnectWeb.Plugs.Auth

  def index(conn, _params) do
    user = %User{company_id: company_id} = Auth.current_user(conn)

    auction_payloads =
      user
      |> Auctions.list_auctions()
      |> Enum.map(fn auction ->
        auction
        |> Auctions.fully_loaded()
        |> AuctionPayload.get_auction_payload!(company_id)
      end)

    render(conn, "index.json", data: auction_payloads)
  end

  def show(conn, %{"auction_id" => auction_id}) do
    auction = Auctions.get_auction(auction_id)
    %User{company_id: company_id} = Auth.current_user(conn)
    auction_payload = AuctionPayload.get_auction_payload!(auction, company_id)

    render(conn, "show.json", data: auction_payload)
  end
end
