defmodule OceanconnectWeb.Api.AuctionFixtureController do
  use OceanconnectWeb, :controller
  alias Oceanconnect.Auctions
  alias Oceanconnect.Auctions.Payloads.{FixturePayload}
  alias Oceanconnect.Accounts.User
  alias OceanconnectWeb.Plugs.Auth

  def index(conn, _params) do
    current_user = %{company_id: company_id} = Auth.current_user(conn)

    fixture_payloads =
      case Auth.current_user_is_admin?(conn) do
        true ->
          Auctions.list_auctions_with_fixtures()
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
end

