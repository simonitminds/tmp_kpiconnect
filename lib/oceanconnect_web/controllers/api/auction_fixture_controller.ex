defmodule OceanconnectWeb.Api.AuctionFixtureController do
  use OceanconnectWeb, :controller
  alias Oceanconnect.Auctions

  alias Oceanconnect.Auctions.{
    Auction,
    AuctionFixture,
    Payloads.FixturePayload,
    Payloads.FixtureEventPayload
  }

  alias Oceanconnect.Deliveries
  alias Oceanconnect.Accounts.User
  alias OceanconnectWeb.Plugs.Auth

  def index(conn, _params) do
    current_user = Auth.current_user(conn)

    fixture_payloads =
      current_user
      |> Auctions.list_auctions()
      |> Enum.reject(&(&1.type != "spot"))
      |> Oceanconnect.Repo.preload(:fixtures)
      |> Enum.reject(&(is_nil(&1.fixtures) or &1.fixtures == []))
      |> Enum.map(fn auction ->
        auction
        |> FixturePayload.get_fixture_payload!(current_user)
      end)
      |> Enum.uniq()

    render(conn, "index.json", data: fixture_payloads)
  end

  def deliver(conn, %{
        "fixture_id" => fixture_id,
        "auction_id" => auction_id,
        "delivery_params" => delivery_params
      }) do
    fixture_id = String.to_integer(fixture_id)
    auction_id = String.to_integer(auction_id)
    delivery_params = Map.merge(delivery_params, %{"delivered" => true})

    with %User{is_admin: true} <- Auth.current_user(conn),
         %Auction{} <- Auctions.get_auction!(auction_id),
         fixture = %AuctionFixture{} <- Auctions.get_fixture!(fixture_id),
         {:ok, delivered_fixture} <- Deliveries.deliver_fixture(fixture, delivery_params) do
      conn
      |> put_status(200)
      |> render("show.json", data: delivered_fixture)
    else
      _ ->
        conn
        |> put_status(421)
        |> render("show.json", %{success: false, message: "Request unsuccessful"})
    end
  end

  def events(conn, %{"fixture_id" => fixture_id}) do
    fixture_id = String.to_integer(fixture_id)

    with fixture = %AuctionFixture{auction_id: auction_id} <- Auctions.get_fixture!(fixture_id),
         auction = %Auction{} <- Auctions.get_auction!(auction_id),
         fixture_event_payload = %FixtureEventPayload{} <-
           FixtureEventPayload.get_payload!(fixture, auction) do
      conn
      |> put_status(200)
      |> render("events.json", data: fixture_event_payload)
    else
      _ ->
        conn
        |> put_status(421)
        |> render("show.json", %{success: false, message: "Request unsuccessful"})
    end
  end
end
