defmodule Oceanconnect.Auctions.AuctionFixtureTest do
  use Oceanconnect.DataCase
  alias Oceanconnect.Auctions
  alias Oceanconnect.Auctions.{AuctionFixture}

  setup do
    auction = insert(:auction, auction_vessel_fuels: [build(:vessel_fuel)])
    fixtures = insert_list(2, :auction_fixture, auction: auction)
    {:ok, %{auction: auction, fixtures: fixtures}}
  end

  test "fixtures_for_auction", %{auction: auction} do
    assert AuctionFixture.from_auction(auction) |> Oceanconnect.Repo.all()
  end

  describe "create_fixtures_snapshot/1" do
    test "creating fixtures with out optional fields " do
      auction = insert(:auction, auction_vessel_fuels: [build(:vessel_fuel, etd: nil)])
      close_auction!(auction)
      :timer.sleep(1500)
      new_state = Auctions.get_auction_state!(auction)

      assert {:ok, [%AuctionFixture{etd: nil}]} = Auctions.create_fixtures_from_state(new_state)
    end
  end

  describe "fixture events" do
    setup do
      auction = insert(:auction, auction_vessel_fuels: [build(:vessel_fuel)])
      state = Auctions.get_auction_state!(auction)

      %Oceanconnect.Auctions.Auction{
        id: auction_id,
        auction_vessel_fuels: [vessel_fuel | _rest],
        suppliers: [supplier]
      } = auction

      bid = create_bid(3.50, 3.50, supplier.id, vessel_fuel.id, auction)
      initial_state = Oceanconnect.Auctions.AuctionStore.AuctionState.from_auction(auction)
      solution = %Oceanconnect.Auctions.Solution{bids: [bid]}

      state =
        [
          Oceanconnect.Auctions.Command.start_auction(auction, DateTime.utc_now(), nil),
          Oceanconnect.Auctions.Command.process_new_bid(bid, nil),
          Oceanconnect.Auctions.Command.select_winning_solution(
            solution,
            auction,
            DateTime.utc_now(),
            "Smith",
            nil
          )
        ]
        |> Enum.reduce(initial_state, fn command, state ->
          {:ok, events} = Oceanconnect.Auctions.Aggregate.process(state, command)

          events
          |> Enum.reduce(state, fn event, state ->
            {:ok, state} = Oceanconnect.Auctions.Aggregate.apply(state, event)
            state
          end)
        end)

      {:ok, %{auction: auction, state: state}}
    end

    test "creating a fixture creates a fixture_created_event", %{auction: auction, state: state} do
      auction_id = auction.id
      {:ok, fixtures} = Auctions.finalize_auction(auction, state)

      assert [
               %Oceanconnect.Auctions.AuctionEvent{
                 type: :fixture_created,
                 auction_id: ^auction_id
               }
             ] = Oceanconnect.Auctions.AuctionEventStorage.events_by_auction(auction_id)
    end

    test "updating a fixture creates a fixture_updated_event", %{auction: auction, state: state} do
      auction_id = auction.id
      Auctions.finalize_auction(auction, state)
      fixtures = Auctions.fixtures_for_auction(auction)
      fixture = hd(fixtures)

      {:ok, updated_fixture} =
        Auctions.update_fixture(fixture, %{quantity: Decimal.add(fixture.quantity, 1000)})

      assert [
               %Oceanconnect.Auctions.AuctionEvent{
                 type: :fixture_updated,
                 auction_id: ^auction_id,
                 data: %{original: ^fixture, updated: %Ecto.Changeset{}}
               },
               %Oceanconnect.Auctions.AuctionEvent{
                 type: :fixture_created,
                 auction_id: ^auction_id
               }
             ] = Oceanconnect.Auctions.AuctionEventStorage.events_by_auction(auction_id)
    end
  end
end
