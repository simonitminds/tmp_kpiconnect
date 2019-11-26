defmodule Oceanconnect.AuctionFixture.IndexPage do
  use Oceanconnect.Page

  def visit do
    navigate_to("/fixtures")
  end

  def is_current_path? do
    current_path() == "/fixtures"
  end

  def has_auction_fixtures?(auction, fixtures) when is_list(fixtures) do
    fixture_elements =
      fixtures
      |> Enum.reduce([], fn fixture, acc ->
        [
          find_element(:css, ".qa-auction-#{auction.id}")
          |> find_within_element(:css, ".qa-fixture-#{fixture.id}")
          | acc
        ]
      end)

    length(fixture_elements) == length(fixtures)
  end

  def fixture_has_details?(fixture) do
    fixture
    |> Map.from_struct()
    |> Enum.all?(fn {key, value} ->
      fixture_has_details?(fixture.id, key, value)
    end)
  end

  def fixture_has_details?(fixture_id, :fuel, fuel) do
    inner_text({:css, ".qa-fixture-#{fixture_id} .qa-fixture-fuel"}) == fuel.name
  end

  def fixture_has_details?(fixture_id, :vessel, vessel) do
    inner_text({:css, ".qa-fixture-#{fixture_id} .qa-fixture-vessel"}) == vessel.name
  end

  def fixture_has_details?(fixture_id, :supplier, supplier) do
    inner_text({:css, ".qa-fixture-#{fixture_id} .qa-fixture-supplier"}) == supplier.name
  end

  def fixture_has_details?(fixture_id, :price, price) do
    inner_text({:css, ".qa-fixture-#{fixture_id} .qa-fixture-price"}) == "#{price}0"
  end

  def fixture_has_details?(fixture_id, :quantity, quantity) do
    inner_text({:css, ".qa-fixture-#{fixture_id} .qa-fixture-quantity"}) == "#{quantity} M/T"
  end

  # TODO: format dates properly to match front end (DD-MM-YYYY)
  # def fixture_has_details?(fixture_id, :eta, eta) do
  #   inner_text({:css, ".qa-fixture-#{fixture_id} .qa-fixture-eta"}) == eta
  # end

  # def fixture_has_details?(fixture_id, :etd, etd) do
  #   inner_text({:css, ".qa-fixture-#{fixture_id} .qa-fixture-etd"}) == etd
  # end

  def fixture_has_details?(_, _, _), do: true

  def show_report(fixture) do
    click({:css, ".qa-fixture-#{fixture.id}-show_report"})
  end

  def fixture_has_events?(fixture, events) do
    event_elements =
      events
      |> Enum.reduce([], fn event, acc ->
        [
          find_element(:css, ".qa-fixture-#{fixture.id}-events")
          |> find_within_element(:css, ".qa-fixture-event-#{event.id}")
          | acc
        ]
      end)

    length(event_elements) == length(events)
  end

  def event_has_details?(fixture, %{type: :fixture_created} = event) do
    keys =
      fixture
      |> Map.from_struct()
      |> Map.keys()
      |> Enum.filter(fn key ->
        key =
          key
          |> Atom.to_string()

        String.contains?(key, "original_") and !String.ends_with?(key, "_id")
      end)

    Enum.all?(keys, fn key ->
      fixture
      |> Map.get(key)
      |> event_has_details?(
        key
        |> Atom.to_string()
        |> String.replace_leading("original_", ""),
        fixture,
        event
      )
    end)
  end

  def event_has_details?(value, key, fixture, event) when key in ["fuel", "supplier", "vessel"] do
    value.name ==
      find_element(:css, ".qa-fixture-event-#{event.id}-#{key}")
      |> inner_text()
  end

  def event_has_details?(value, "price", fixture, event) do
    "$#{value}0" ==
      find_element(:css, ".qa-fixture-event-#{event.id}-price")
      |> inner_text()
  end

  def event_has_details?(value, "quantity", fixture, event) do
    "#{value} M/T" ==
      find_element(:css, ".qa-fixture-event-#{event.id}-quantity")
      |> inner_text()
  end

  # TODO: again format dates here to match what's on the front end (DD-MM-YYYY)
  # def event_has_details?(value, key, fixture, event) when key in ["eta", "etd"] do
  # end

  def event_has_details?(_, _, _, _), do: true
end
