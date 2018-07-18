defmodule OceanconnectWeb.Api.CompanyBargesController do
  use OceanconnectWeb, :controller
  alias Oceanconnect.{Accounts}
  alias Oceanconnect.Accounts.{Company}
  alias Oceanconnect.Auctions.{Auction, AuctionEventStore, AuctionPayload}
  alias OceanconnectWeb.Plugs.Auth

  def index(conn, %{"company_id" => company_id}) do
    current_user = Auth.current_user(conn)
    company_id = String.to_integer(company_id)
    if Accounts.authorized_for_company?(current_user, company_id) do
      barges = Accounts.list_company_barges(company_id)
      render(conn, "index.json", data: barges)
    else
      conn
      |> put_status(401)
      |> render(OceanconnectWeb.ErrorView, "401.json", data: [])
    end
  end
end
