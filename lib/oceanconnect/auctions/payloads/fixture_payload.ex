defmodule Oceanconnect.Auctions.Payloads.FixturePayload do
  import Oceanconnect.Auctions.Guards

  alias __MODULE__
  alias Oceanconnect.Auctions

  alias Oceanconnect.Auctions.Auction
  alias Oceanconnect.Accounts.User

  defstruct auction: nil,
            fixtures: []

  def get_fixture_payload!(auction = %Auction{}, %User{is_admin: true}) do
    get_buyer_fixture_payload!(auction)
  end

  def get_fixture_payload!(auction = %Auction{buyer_id: buyer_id}, %User{company_id: company_id}) do
    cond do
      buyer_id == company_id ->
        get_buyer_fixture_payload!(auction)
      true ->
        get_supplier_fixture_payload!(auction, company_id)
    end
  end

  def get_buyer_fixture_payload!(auction) do
    %FixturePayload{
      auction: auction,
      fixtures:
        auction
        |> Auctions.fixtures_for_auction()
        |> format_fixture_prices()
    }
  end

  def get_supplier_fixture_payload!(auction, supplier_id) do
    %FixturePayload{
      auction: Map.delete(auction, :suppliers),
      fixtures:
        auction
        |> Auctions.fixtures_for_auction()
        |> Enum.reject(& &1.supplier_id != supplier_id)
        |> format_fixture_prices()
    }
  end

  defp format_fixture_prices(fixtures) do
    fixtures
    |> Enum.map(fn %{price: price} = fixture ->
      %{fixture | price: Decimal.to_string(price)}
    end)
  end

  def json_from_payload(%FixturePayload{
    auction: auction,
    fixtures: fixtures
      }) do
    %{
      auction: auction,
      fixtures: fixtures
    }
  end
end
