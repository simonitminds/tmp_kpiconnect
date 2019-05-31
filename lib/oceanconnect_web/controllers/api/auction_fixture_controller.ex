defmodule OceanconnectWeb.Api.AuctionFixtureController do
  use OceanconnectWeb, :controller
  alias Oceanconnect.Auctions
  alias Oceanconnect.Auctions.Payloads.{FixturePayload}
  alias Oceanconnect.Accounts.User
  alias OceanconnectWeb.Plugs.Auth

  def index(conn, _params) do
    company_id = Auth.current_user(conn).company_id

    fixture_payloads =
      case Auth.current_user_is_admin?(conn) do
        true ->
          Auctions.list_auctions_with_fixtures()
          |> Enum.map(fn auction ->
            auction
            |> FixturePayload.get_fixture_payload!()
          end)
          |> Enum.uniq()

        false ->
          Auctions.list_participating_auctions_with_fixtures(company_id)
          |> Enum.map(fn auction ->
            auction
            |> FixturePayload.get_fixture_payload!()
          end)
          |> Enum.uniq()
      end

    render(conn, "index.json", data: fixture_payloads)
  end
end

