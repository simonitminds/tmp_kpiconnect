defmodule Oceanconnect.Auctions.AuctionEventHandlerTest do
  use Oceanconnect.DataCase
  alias Oceanconnect.Auctions
  alias Oceanconnect.Auctions

  alias Oceanconnect.Auctions.{
    Auction,
    AuctionEvent,
    AuctionEventStore,
    AuctionSupervisor,
    AuctionFixture
  }

  setup do
    supplier_company = insert(:company)
    supplier2_company = insert(:company)
    buyer_company = insert(:company, is_supplier: false)
    supplier = insert(:user, company: supplier_company)
    supplier2 = insert(:user, company: supplier2_company)

    vessel_fuel = insert(:vessel_fuel)

    auction =
      insert(
        :auction,
        duration: 1_000,
        decision_duration: 1_000,
        suppliers: [supplier_company, supplier2_company],
        buyer: buyer_company,
        auction_vessel_fuels: [vessel_fuel]
      )
      |> Auctions.fully_loaded()

    {:ok, _pid} =
      start_supervised(
        {AuctionSupervisor,
         {auction, %{exclude_children: [:auction_reminder_timer, :auction_scheduler]}}}
      )

    on_exit(fn ->
      case DynamicSupervisor.which_children(Oceanconnect.Auctions.AuctionsSupervisor) do
        [] ->
          nil

        children ->
          Enum.map(children, fn {_, pid, _, _} ->
            Process.unlink(pid)
            Process.exit(pid, :shutdown)
          end)
      end
    end)

    {:ok,
     %{
       auction: auction,
       supplier_company: supplier_company,
       supplier2_company: supplier2_company,
       vessel_fuel: vessel_fuel,
       supplier: supplier,
       supplier2: supplier2
     }}
  end

  test "fixture records are created when an auction closes", %{
    auction: auction = %Auction{id: auction_id},
    vessel_fuel: vessel_fuel
  } do
    vessel_fuel_id = vessel_fuel.id
    assert :ok = Phoenix.PubSub.subscribe(:auction_pubsub, "auction:#{auction_id}")

    Auctions.start_auction(auction)

    bid =
      create_bid(1.25, nil, hd(auction.suppliers).id, vessel_fuel_id, auction, true)
      |> Auctions.place_bid()

    Auctions.end_auction(auction)
    state = Auctions.get_auction_state!(auction)

    Auctions.select_winning_solution(
      [bid],
      state.product_bids,
      auction,
      "Winner Winner Chicken Dinner.",
      "Agent 9"
    )

    :timer.sleep(200)

    state = Auctions.get_auction_state!(auction)

    events = AuctionEventStore.event_list(auction_id)

    assert Enum.any?(events, fn event -> event.type == :auction_state_snapshotted end)
    assert [%AuctionFixture{}] = Auctions.fixtures_for_auction(auction)
  end
end
