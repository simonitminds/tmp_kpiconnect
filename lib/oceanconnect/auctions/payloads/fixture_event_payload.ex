defmodule Oceanconnect.Auctions.Payloads.FixtureEventPayload do
  alias Oceanconnect.Auctions
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
    IO.inspect(events, label: "WHAT?!")

    %{
      fixture: Auctions.get_fixture!(fixture.id),
      auction: Auctions.get_auction!(auction.id),
      events:
        Enum.map(events, fn event ->
          data = event.data

          cond do
            event.type in [:fixture_created, :fixture_delivered, :fixture_changes_proposed] ->
              delivered = data.fixture.delivered
              fixture =
                # if !delivered do
                #   keys =
                #     Map.keys(data.fixture)
                #     |> Enum.filter(fn key ->
                #       Atom.to_string(key)
                #       |> String.starts_with?("delivered_")
                #     end)

                #   Map.drop(data.fixture, keys)
                # else
                #   data.fixture
                # end
                data.fixture
                |> format_fixture_prices()
                |> format_fixture_quantities()
                |> IO.inspect
                |> Auctions.strip_non_loaded()

              %{event | data: %{data | fixture: fixture}}

            true ->
              fixture =
                data.original
                |> format_fixture_prices()
                |> format_fixture_quantities()
                |> Auctions.strip_non_loaded()

              %{event | data: %{data | original: fixture}}
          end
        end)
        |> format_event_types()
    }
  end

  defp format_event_types(events) do
    events
    |> Enum.map(fn event ->
      type =
        ~r/_/
        |> Regex.replace(Atom.to_string(event.type), " ")
        |> String.capitalize()

      %{event | type: type}
    end)
  end

  defp format_fixture_prices(
         %{
           price: %Decimal{} = price,
           delivered: true,
           delivered_price: %Decimal{} = delivered_price
         } = fixture
       ) do
    %{
      fixture
      | price: Decimal.to_string(price),
        delivered_price: Decimal.to_string(delivered_price)
    }
  end

  defp format_fixture_prices(%{price: %Decimal{} = price} = fixture) do
    %{fixture | price: Decimal.to_string(price)}
  end

  defp format_fixture_prices(fixture), do: fixture

  defp format_fixture_quantities(%{quantity: %Decimal{} = quantity, delivered: true, delivered_quantity: %Decimal{} = delivered_quantity} = fixture) do
    %{
      fixture
      | quantity: Decimal.to_string(quantity),
        delivered_quantity: Decimal.to_string(delivered_quantity)
    }
  end

  defp format_fixture_quantities(%{quantity: %Decimal{} = quantity} = fixture) do
    %{fixture | quantity: Decimal.to_string(quantity)}
  end

  defp format_fixture_quantities(fixture), do: fixture
end
