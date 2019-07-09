defmodule Oceanconnect.AuctionFixture.IndexTest do
  use Oceanconnect.FeatureCase
  alias Oceanconnect.AuctionFixture.IndexPage
  alias Oceanconnect.Auctions

  hound_session()

  setup do
    buyer_company = insert(:company)
    buyer = insert(:user, company: buyer_company)
    supplier_company = insert(:company, is_supplier: true)
    supplier = insert(:user, company: supplier_company)

    fuel = insert(:fuel)
    vessel = insert(:vessel)
    vessel_fuel = insert(:vessel_fuel, fuel: fuel, vessel: vessel)

    auction =
      insert(:auction,
        buyer: buyer_company,
        suppliers: [supplier_company],
        auction_vessel_fuels: [vessel_fuel]
      )

    auction_state = close_auction!(auction)

    {:ok, _fixtures} = Auctions.create_fixtures_from_state(auction_state)
    fixtures =
      Auctions.fixtures_for_auction(auction)
      |> format_fixture_prices()

    {:ok, %{
      auction: auction,
      buyer: buyer,
      supplier: supplier,
      fixtures: fixtures
    }}
  end

  describe "buyer" do
    setup %{buyer: buyer} do
      login_user(buyer)
      IndexPage.visit()
      :timer.sleep(200)
      :ok
    end

    test "can visit the fixtures index page and see fixtures grouped by auctions", %{auction: auction, fixtures: fixtures} do
      assert IndexPage.is_current_path?()
      assert IndexPage.has_auction_fixtures?(auction, fixtures)
    end

    test "can see a fixture's details", %{auction: auction, fixtures: fixtures} do
      assert IndexPage.is_current_path?()
      assert IndexPage.has_auction_fixtures?(auction, fixtures)
      fixture = hd(fixtures)
      assert IndexPage.fixture_has_details?(fixture)
    end

    test "can view report with correct events", %{auction: auction, fixtures: fixtures} do
      assert IndexPage.is_current_path?()
      assert IndexPage.has_auction_fixtures?(auction, fixtures)
      fixture = hd(fixtures)
      assert IndexPage.fixture_has_details?(fixture)

      events = Auctions.AuctionEventStore.fixture_events(auction.id, fixture.id)
      IndexPage.show_report(fixture)
      assert IndexPage.fixture_has_events?(fixture, events)
    end

    test "fixture created event has correct details", %{auction: auction, fixtures: fixtures} do
      assert IndexPage.is_current_path?()
      assert IndexPage.has_auction_fixtures?(auction, fixtures)
      fixture = hd(fixtures)
      assert IndexPage.fixture_has_details?(fixture)

      events = Auctions.AuctionEventStore.fixture_events(auction.id, fixture.id)
      IndexPage.show_report(fixture)
      assert IndexPage.fixture_has_events?(fixture, events)

      event = Enum.find(events, & &1.type == :fixture_created)
      assert IndexPage.event_has_details?(fixture, event)
    end
  end

  defp format_fixture_prices(fixtures) when is_list(fixtures) do
    Enum.map(fixtures, fn fixture ->
      fixture
      |> format_fixture_prices()
    end)
  end

  defp format_fixture_prices(%{price: price, original_price: original_price, delivered_price: delivered_price} = fixture) do
    %{fixture
      | price: Decimal.to_string(price),
        original_price: Decimal.to_string(original_price),
        delivered_price: Decimal.to_string(delivered_price)}
  end
end
