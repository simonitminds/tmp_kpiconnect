defmodule EventMigrator do
  alias Oceanconnect.Repo

  alias Oceanconnect.Auctions.{
    AuctionEventStorage,
    AuctionEvent,
    Auction,
    AuctionStore,
    AuctionBid,
    AuctionStore,
    AuctionVesselFuel
  }

  def migrate do
    Application.ensure_started(Repo, [])

    Repo.all(AuctionEventStorage)
    |> Repo.preload(
      auction: [
        :port,
        :vessels,
        :fuels,
        :auction_suppliers,
        [auction_vessel_fuels: [:vessel, :fuel]],
        [buyer: :users],
        [suppliers: :users]
      ]
    )
    |> Enum.map(&migrate_event/1)
  end

  def migrate_event(%AuctionEventStorage{auction: auction = %Auction{vessels: vessels}, event: event})
      when length(vessels) > 1 do
    event = event |> AuctionEventStorage.hydrate_event()
    #|> migrate_multi_vessel_event()
    IO.inspect("I DIDN't Migrate THIS:  auction: #{auction.id} event: #{event.type}")
    event
  end

  def migrate_event(%AuctionEventStorage{
        auction: auction = %Auction{auction_vessel_fuels: [vessel_fuel]},
        event: event
      }) do
    event
    |> AuctionEventStorage.hydrate_event()
    |> migrate_event(auction, vessel_fuel)
  end

  # switch fuel_id in auction_state with vessel fuel
  def migrate_event(
        event = %AuctionEvent{type: type, auction_id: auction_id, data: %{state: %{product_bids: product_bids}}},
        _auction,
        vessel_fuel = %{id: vessel_fuel_id}
      ) do
    keys = Map.keys(product_bids)
    |> Enum.sort # order matters
    |> Enum.map(fn(key) ->
      id = String.to_integer(key)
      auction_vessel_fuel = Repo.get_by(AuctionVesselFuel, fuel_id: id, auction_id: auction_id)
      auction_vessel_fuel.id
    end)

    product_bid_state_map = Enum.reduce(product_bids, %{}, fn({key, product_bid_state}, acc) ->
      id = String.to_integer(key)
      auction_vessel_fuel = Repo.get_by(AuctionVesselFuel, fuel_id: id, auction_id: auction_id)
      correct_id = auction_vessel_fuel.id
      updated_product_bid_state = update_product_bid_state(product_bid_state, correct_id)
      Map.put(acc, correct_id, updated_product_bid_state)
    end)
    # TODO here product bids are %{"fuel_id" => %ProductBidState{}} we need to look up the fuel_id find the appropriate vessel_fuel_id and pass it down and change the key fuel_id to be the value of the vessel_fuel_id

     %AuctionEvent{
       event
       | data: %{event.data | state: %{event.data.state | product_bids: product_bid_state_map}}
     }
  end

  def migrate_event(event, _auction, _vessel_fuel) do
    event
  end

  def migrate_multi_vessel_event(event) do
    event
  end

  def update_product_bid_state(product_bid_state, vessel_fuel_id) do
    updated_state = Map.merge(%AuctionStore.ProductBidState{}, product_bid_state)

    final_product_bid_state =
      %{
        updated_state
        | vessel_fuel_id: vessel_fuel_id,
        lowest_bids:
        Enum.map(updated_state.lowest_bids, &convert_product_bid(&1, vessel_fuel_id)),
        minimum_bids:
        Enum.map(updated_state.minimum_bids, &convert_product_bid(&1, vessel_fuel_id)),
        bids: Enum.map(updated_state.bids, &convert_product_bid(&1, vessel_fuel_id)),
        active_bids:
        Enum.map(updated_state.active_bids, &convert_product_bid(&1, vessel_fuel_id)),
        inactive_bids:
        Enum.map(updated_state.inactive_bids, &convert_product_bid(&1, vessel_fuel_id))
      }
  end

  def convert_product_bid(auction_bid, vessel_fuel_id) do
    bid = AuctionBid.from_event_bid(auction_bid)
    %{bid | vessel_fuel_id: vessel_fuel_id}
  end
end

defmodule Mix.Tasks.MigrateEventsToMultiVessel do
  use Mix.Task

  @shortdoc "Migrates Events prior to Multi-Vessel to the new Multi-Vessel format."
  def run(_args) do
    EventMigrator.migrate() |> Enum.count
  end
end
