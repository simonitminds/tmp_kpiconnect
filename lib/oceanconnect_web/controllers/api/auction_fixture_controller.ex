defmodule OceanconnectWeb.Api.AuctionFixtureController do
  use OceanconnectWeb, :controller
  alias Oceanconnect.Auctions
  alias Oceanconnect.Auctions.{Auction, AuctionFixture, Payloads.FixturePayload}
  alias Oceanconnect.Deliveries
  alias Oceanconnect.Accounts.User
  alias OceanconnectWeb.Plugs.Auth

  def index(conn, _params) do
    current_user = %{company_id: company_id} = Auth.current_user(conn)

    fixture_payloads =
      case Auth.current_user_is_admin?(conn) do
        true ->
          Auctions.list_auctions()
          |> Enum.reject(& &1.type != "spot")
          |> Oceanconnect.Repo.preload(:fixtures)
          |> Enum.reject(& is_nil(&1.fixtures) or &1.fixtures == [])
          |> Enum.map(fn auction ->
            auction
            |> FixturePayload.get_fixture_payload!(current_user)
          end)
          |> Enum.uniq()

        false ->
          Auctions.list_participating_auctions(company_id)
          |> Enum.reject(& &1.type != "spot")
          |> Oceanconnect.Repo.preload(:fixtures)
          |> Enum.reject(& is_nil(&1.fixtures) or &1.fixtures == [])
          |> Enum.map(fn auction ->
            auction
            |> FixturePayload.get_fixture_payload!(current_user)
          end)
          |> Enum.uniq()
      end

    render(conn, "index.json", data: fixture_payloads)
  end

  def deliver(conn, %{"fixture_id" => fixture_id, "auction_id" => auction_id, "delivered" => delivered}) do
    fixture_id = String.to_integer(fixture_id)
    auction_id = String.to_integer(auction_id)

    with current_user = %User{is_admin: true} <- Auth.current_user(conn),
         auction = %Auction{} <- Auctions.get_auction!(auction_id),
         fixture = %AuctionFixture{} <- Auctions.get_fixture!(fixture_id),
         {:ok, delivered_fixture} <- Deliveries.deliver_fixture(fixture, %{"delivered" => delivered}) do
      conn
      |> put_status(200)
      |> render("show.json", data: delivered_fixture)
    else
      _ ->
        conn
        |> put_status(421)
        |> render("show.json", %{success: false, message: "Request successful"})
    end
  end
end

