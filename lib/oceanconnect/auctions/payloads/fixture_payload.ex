defmodule Oceanconnect.Auctions.Payloads.FixturePayload do
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
    }
  end

  def get_supplier_fixture_payload!(auction, supplier_id) do
    %FixturePayload{
      auction: Map.delete(auction, :suppliers),
      fixtures:
        auction
        |> Auctions.fixtures_for_auction()
        |> Enum.reject(&(&1.supplier_id != supplier_id))
    }
  end

  def json_from_payload(%FixturePayload{
        auction: auction,
        fixtures: fixtures
      }) do
    %{
      auction: auction,
      fixtures:
        fixtures
        |> format_fixtures()
    }
  end

  defp format_fixtures(fixtures) when is_list(fixtures) do
    fixtures
    |> Enum.map(fn fixture ->
      fixture
      |> format_fixture_prices()
      |> format_fixture_quantities()
      |> Auctions.strip_non_loaded()
    end)
  end

  defp format_fixture_prices(
         %{
           price: %Decimal{} = price,
           original_price: %Decimal{} = original_price,
           delivered_price: %Decimal{} = delivered_price
         } = fixture
       ) do
    %{
      fixture
      | price: Decimal.to_string(price),
        original_price: Decimal.to_string(original_price),
        delivered_price: Decimal.to_string(delivered_price)
    }
  end

  defp format_fixture_prices(
         %{price: %Decimal{} = price, original_price: %Decimal{} = original_price} = fixture
       ) do
    %{
      fixture
      | price: Decimal.to_string(price),
        original_price: Decimal.to_string(original_price)
    }
  end

  defp format_fixture_prices(
         %{price: %Decimal{} = price, delivered_price: %Decimal{} = delivered_price} = fixture
       ) do
    %{
      fixture
      | price: Decimal.to_string(price),
        delivered_price: Decimal.to_string(delivered_price)
    }
  end

  defp format_fixture_prices(%{price: %Decimal{} = price} = fixture) do
    %{
      fixture
      | price: Decimal.to_string(price)
    }
  end

  defp format_fixture_prices(fixture), do: fixture

  defp format_fixture_quantities(
         %{
           quantity: %Decimal{} = quantity,
           original_quantity: %Decimal{} = original_quantity,
           delivered_quantity: %Decimal{} = delivered_quantity
         } = fixture
       ) do
    %{
      fixture
      | quantity: Decimal.to_string(quantity),
        original_quantity: Decimal.to_string(original_quantity),
        delivered_quantity: Decimal.to_string(delivered_quantity)
    }
  end

  defp format_fixture_quantities(
         %{quantity: %Decimal{} = quantity, original_quantity: %Decimal{} = original_quantity} =
           fixture
       ) do
    %{
      fixture
      | quantity: Decimal.to_string(quantity),
        original_quantity: Decimal.to_string(original_quantity)
    }
  end

  defp format_fixture_quantities(
         %{quantity: %Decimal{} = quantity, delivered_quantity: %Decimal{} = delivered_quantity} =
           fixture
       ) do
    %{
      fixture
      | quantity: Decimal.to_string(quantity),
        delivered_quantity: Decimal.to_string(delivered_quantity)
    }
  end

  defp format_fixture_quantities(%{quantity: %Decimal{} = quantity} = fixture) do
    %{
      fixture
      | quantity: Decimal.to_string(quantity)
    }
  end

  defp format_fixture_quantities(fixture), do: fixture
end
