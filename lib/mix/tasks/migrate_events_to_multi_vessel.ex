defmodule EventMigrator do
  alias Oceanconnect.Repo

  alias Oceanconnect.Auctions.{
    AuctionEventStorage,
    AuctionEvent,
    Auction,
    AuctionStore,
    AuctionBid,
    AuctionStore,
    AuctionVesselFuel,
    SolutionCalculator,
    Solution
  }

  import Ecto.Query

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
    |> List.flatten()
  end

  def migrate_event(
        storage = %AuctionEventStorage{
          auction: %Auction{},
          event: event
        }
      ) do
    final_event =
      event
      |> AuctionEventStorage.hydrate_event()
      |> migrate_event()

    final_event = case final_event do
      %AuctionEvent{} = event -> event
      [event] -> event
      events -> events
    end
    if is_list(final_event) && length(final_event) > 1 do
      events = final_event |> List.flatten
      Enum.map(events, fn(event) ->
        changeset =
        AuctionEventStorage.changeset(%AuctionEventStorage{}, %{event: :erlang.term_to_binary(event)})
        Ecto.Multi.new()
        |> Ecto.Multi.insert_or_update(:insert_or_update, changeset)
        |> Repo.transaction()
      end)
    else
    changeset =
      AuctionEventStorage.changeset(storage, %{event: :erlang.term_to_binary(final_event)})
      Ecto.Multi.new()
      |> Ecto.Multi.insert_or_update(:insert_or_update, changeset)
      |> Repo.transaction()
    end
  end

  # switch fuel_id in auction_state with vessel fuel
  def migrate_event(
        event = %AuctionEvent{
          type: :bid_placed,
          auction_id: auction_id,
          data: %{bid: bid = %{fuel_id: fuel_id}, state: state}
        }
      ) do
    vessel_fuels =
      from(avf in AuctionVesselFuel,
        where: avf.fuel_id == ^fuel_id and avf.auction_id == ^auction_id
      )
      |> Repo.all()
      |> Enum.map(fn vf ->
        bid =
          bid
          |> Map.from_struct()
          |> Map.put(:vessel_fuel_id, "#{vf.id}")
          |> Map.drop([:fuel_id])
          |> AuctionBid.from_event_bid()

        %AuctionEvent{event | data: %{event.data | bid: bid}}
      end)
  end

  def migrate_event(event = %AuctionEvent{type: :winning_solution_selected, auction_id: auction_id, data: %{solution: _solution, state: %{
    product_bids: product_bids,
    solutions: _solutions,
    winning_solution: _winning_solution
  }}}) do
    fuel_ids =
    Map.keys(product_bids)
    |> Enum.sort()

  fuel_to_vessel_fuel_lookup =
    from(avf in AuctionVesselFuel,
      where: avf.fuel_id in ^fuel_ids and avf.auction_id == ^auction_id
    )
    |> Repo.all()
    |> Enum.group_by(fn avf -> "#{avf.fuel_id}" end, fn %{id: avf_id} -> "#{avf_id}" end)

  product_bid_state_map =
    Enum.reduce(product_bids, %{}, fn {fuel_id, product_bid_state}, acc ->
        fuel_to_vessel_fuel_lookup[fuel_id]
        |> Enum.reduce(acc, fn vfid, acc ->
          updated_product_bid_state = update_product_bid_state(product_bid_state, vfid)
          Map.put(acc, vfid, updated_product_bid_state)
        end)
    end)

  %AuctionEvent{
    event
    | data: %{
        event.data
        | state: %{
            event.data.state
            | product_bids: product_bid_state_map,
              solutions:
                update_solutions(event.data.state.solutions, fuel_to_vessel_fuel_lookup),
              winning_solution:
                update_solution(event.data.state.winning_solution, fuel_to_vessel_fuel_lookup)
          },
          solution: update_solution(event.data.solution, fuel_to_vessel_fuel_lookup)
      }
  }
  end
  def migrate_event(
        event = %AuctionEvent{
          type: _type,
          auction_id: auction_id,
          data: %{
            state:
              state = %{
                product_bids: product_bids,
                solutions: %SolutionCalculator{},
                winning_solution: _winning_solution
              }
          }
        }
      ) do
    fuel_ids =
      Map.keys(product_bids)
      |> Enum.sort()

    fuel_to_vessel_fuel_lookup =
      from(avf in AuctionVesselFuel,
        where: avf.fuel_id in ^fuel_ids and avf.auction_id == ^auction_id
      )
      |> Repo.all()
      |> Enum.group_by(fn avf -> "#{avf.fuel_id}" end, fn %{id: avf_id} -> "#{avf_id}" end)

    product_bid_state_map =
      Enum.reduce(product_bids, %{}, fn {fuel_id, product_bid_state}, acc ->
          fuel_to_vessel_fuel_lookup[fuel_id]
          |> Enum.reduce(acc, fn vfid, acc ->
            updated_product_bid_state = update_product_bid_state(product_bid_state, vfid)
            Map.put(acc, vfid, updated_product_bid_state)
          end)
      end)

    %AuctionEvent{
      event
      | data: %{
          event.data
          | state: %{
              event.data.state
              | product_bids: product_bid_state_map,
                solutions:
                  update_solutions(event.data.state.solutions, fuel_to_vessel_fuel_lookup),
                winning_solution:
                  update_solution(event.data.state.winning_solution, fuel_to_vessel_fuel_lookup)
            }
        }
    }
  end

  def migrate_event(event) do
    event
  end

  def update_bid_list(bids, fuel_to_vessel_fuel_lookup) do
    Enum.map(bids, fn bid ->
      fuel_to_vessel_fuel_lookup[bid.fuel_id]
        |> Enum.map(fn vessel_fuel_id ->
          Map.put(bid, :vessel_fuel_id, vessel_fuel_id)
          |> Map.drop([:fuel_id])
        end)
    end)
    |> List.flatten
  end

  def update_solutions(solution = %SolutionCalculator{}, fuel_to_vessel_fuel_lookup) do
    %SolutionCalculator{
      solution
      | best_single_supplier:
          update_solution(solution.best_single_supplier, fuel_to_vessel_fuel_lookup),
        best_overall: update_solution(solution.best_overall, fuel_to_vessel_fuel_lookup),
        best_by_supplier:
          Enum.reduce(solution.best_by_supplier, %{}, fn {supplier_id, solution}, acc ->
            Map.put(acc, supplier_id, update_solution(solution, fuel_to_vessel_fuel_lookup))
          end)
    }
  end

  def update_solution(nil, _fuel_to_vessel_fuel_lookup), do: nil
  def update_solution(solution = %Solution{bids: []}, _fuel_to_vessel_fuel_lookup) do
    solution
  end
  def update_solution(solution = %Solution{bids: bids}, fuel_to_vessel_fuel_lookup) do
    updated_bids = update_bid_list(bids, fuel_to_vessel_fuel_lookup)
    %Solution{solution | bids: updated_bids}
  end

  def update_product_bid_state(product_bid_state, vessel_fuel_id) do
    updated_state =
      Map.merge(%AuctionStore.ProductBidState{}, product_bid_state)
      |> Map.put(:vessel_fuel_id, vessel_fuel_id)
      |> Map.drop([:fuel_id])

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
    %{bid | vessel_fuel_id: vessel_fuel_id} |> Map.drop([:fuel_id])
  end
end

defmodule Mix.Tasks.MigrateEventsToMultiVessel do
  use Mix.Task

  @shortdoc "Migrates Events prior to Multi-Vessel to the new Multi-Vessel format."
  def run(_args) do
    EventMigrator.migrate()
    nil
  end
end
