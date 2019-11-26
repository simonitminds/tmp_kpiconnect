defmodule Oceanconnect.Auctions.Payloads.FixtureEventPayload do
  alias Oceanconnect.Auctions
  alias Oceanconnect.Accounts
  alias Oceanconnect.Auctions.{Auction, AuctionFixture, AuctionEventStore}

  defstruct auction: nil,
            fixture: nil,
            events: []

  def get_payload!(
        %AuctionFixture{id: fixture_id, auction_id: auction_id} = fixture,
        %Auction{} = auction
      ) do
    %__MODULE__{
      fixture: fixture,
      auction: auction,
      events: AuctionEventStore.fixture_events(auction_id, fixture_id)
    }
  end

  def json_from_payload(%__MODULE__{
        fixture: fixture,
        auction: auction,
        events: events
      }) do
    %{
      fixture: format_fixture(fixture),
      auction:
        auction
        |> Auctions.strip_non_loaded(),
      events: format_events(events)
    }
  end

  defp format_events(events) when is_list(events) do
    events
    |> Enum.map(&format_events(&1))
  end

  defp format_events(%{id: id, type: type, data: %{fixture: fixture}, time_entered: time_entered})
       when type in [:fixture_created, :fixture_delivered] do
    %{
      id: id,
      type: format_event_type(type),
      fixture: format_fixture(fixture),
      time_entered: time_entered
    }
  end

  defp format_events(%{
         id: id,
         type: :fixture_updated,
         data: %{original: fixture, updated: %{changes: changes}},
         time_entered: time_entered
       }) do
    changes = format_changes(changes)

    %{
      id: id,
      type: format_event_type(:fixture_updated),
      fixture: format_fixture(fixture),
      changes: changes,
      time_entered: time_entered
    }
  end

  defp format_events(%{
         id: id,
         type: :fixture_changes_proposed,
         data: %{fixture: fixture, changeset: %{changes: changes}, user: user},
         time_entered: time_entered
       }) do
    changes = format_changes(changes)

    %{
      id: id,
      type: format_event_type(:fixture_changes_proposed),
      fixture: format_fixture(fixture),
      changes: changes,
      user: user,
      time_entered: time_entered
    }
  end

  defp format_changes(changes) do
    changes
    |> Enum.reduce(%{}, fn {key, value}, acc ->
      {key, value} = format_change(key, value)
      Map.put(acc, key, value)
    end)
  end

  defp format_change(:fuel_id, fuel_id) do
    %{name: name} = Auctions.get_fuel!(fuel_id)
    {:fuel, name}
  end

  defp format_change(:supplier_id, supplier_id) do
    %{name: name} = Accounts.get_company!(supplier_id)
    {:supplier, name}
  end

  defp format_change(:vessel_id, vessel_id) do
    %{name: name} = Auctions.get_vessel!(vessel_id)
    {:vessel, name}
  end

  defp format_change(key, value), do: {key, value}

  defp format_event_type(type) do
    ~r/_/
    |> Regex.replace(Atom.to_string(type), " ")
    |> String.capitalize()
  end

  defp format_fixture(fixture) do
    fixture
    |> format_fixture_prices()
    |> format_fixture_quantities()
    |> Auctions.strip_non_loaded()
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
