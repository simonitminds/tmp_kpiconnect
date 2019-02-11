defmodule Oceanconnect.Auctions.AuctionStateActions do
  alias Oceanconnect.Auctions

  alias Oceanconnect.Auctions.{
    Auction,
    AuctionBarge,
    AuctionBid,
    AuctionBidCalculator,
    AuctionCache,
    AuctionEvent,
    AuctionScheduler,
    AuctionTimer,
    Command,
    SolutionCalculator,
    Solution
  }
  alias Oceanconnect.Auctions.AuctionStore.{AuctionState, ProductBidState}

  def is_suppliers_first_bid?(%AuctionState{product_bids: product_bids}, %AuctionBid{
        supplier_id: supplier_id
                               }) do
    !Enum.any?(
      product_bids,
      fn {_product_key, %ProductBidState{bids: bids}} ->
        Enum.any?(bids, fn bid -> bid.supplier_id == supplier_id end)
      end
    )
  end

  def is_lowest_bid?(
    state = %AuctionState{},
    bid = %AuctionBid{vessel_fuel_id: vessel_fuel_id}
  ) do
    product_bids = AuctionState.get_state_for_product(state, vessel_fuel_id)

    length(product_bids.lowest_bids) == 0 ||
      hd(product_bids.lowest_bids).supplier_id == bid.supplier_id
  end

  def start_auction(%AuctionState{status: status} = current_state, auction = %Auction{}, user, emit) when status in [:pending, :open] do
    auction = %{ auction | auction_started: DateTime.utc_now()}

    auction
    |> Command.update_cache()
    |> AuctionCache.process_command()

    auction
    |> Command.start_duration_timer()
    |> AuctionTimer.process_command()


    auction
    |> Command.cancel_scheduled_start()
    |> AuctionScheduler.process_command(nil)

    {next_state, _} =
      %AuctionState{current_state | status: :open}
      |> AuctionBidCalculator.process_all(:open)

    next_state = SolutionCalculator.process(next_state, auction)

    AuctionEvent.emit(AuctionEvent.auction_started(auction, next_state, user), emit)
    next_state
  end
  def start_auction(%AuctionState{status: :decision} = current_state, auction = %Auction{}, _user, _emit) do
    auction = %{ auction | auction_started: DateTime.utc_now()}

    auction
    |> Command.update_cache()
    |> AuctionCache.process_command()

    auction
    |> Command.start_decision_duration_timer()
    |> AuctionTimer.process_command()

    auction
    |> Command.cancel_scheduled_start()
    |> AuctionScheduler.process_command(nil)

    current_state
  end
  def start_auction(%AuctionState{} = current_state, %Auction{}, _user, _emit) do
    current_state
  end

  def update_auction(
         auction = %Auction{scheduled_start: start},
         current_state = %{status: :draft},
         emit
       )
       when start != nil do
    update_auction_side_effects(auction, emit)

    current_state
    |> Map.put(:status, :pending)
    |> update_product_bid_state(auction)
  end

  def update_auction(auction, current_state, emit) do
    update_auction_side_effects(auction, emit)
    current_state
    |> update_product_bid_state(auction)
  end

  def update_auction_side_effects(auction, emit) do
    auction
    |> Command.update_cache()
    |> AuctionCache.process_command()

    auction
    |> Command.update_scheduled_start()
    |> AuctionScheduler.process_command(emit)
  end

  def update_product_bid_state(state = %AuctionState{product_bids: product_bids}, %Auction{id: auction_id, auction_vessel_fuels: vessel_fuels}) do
    vessel_fuel_ids = Enum.map(vessel_fuels, &("#{&1.id}"))

    updated_product_bids =
      vessel_fuel_ids
      |> Enum.reduce(%{}, fn(vfid, acc) ->
        if vfid in Map.keys(product_bids) do
          Map.put(acc, vfid, product_bids[vfid])
        else
          Map.put(acc, vfid, ProductBidState.for_product(vfid, auction_id))
        end
      end)

    Map.put(state, :product_bids, updated_product_bids)
  end

  def end_auction(current_state, auction = %Auction{}) do
    auction
    |> Command.update_cache()
    |> AuctionCache.process_command()

    auction
    |> Command.start_decision_duration_timer()
    |> AuctionTimer.process_command()

    %AuctionState{current_state | status: :decision}
  end

  def process_bid(
         current_state = %{auction_id: auction_id, status: status},
         bid = %{vessel_fuel_id: vessel_fuel_id}
       ) do
    product_state =
      AuctionState.get_state_for_product(current_state, vessel_fuel_id) ||
        ProductBidState.for_product(vessel_fuel_id, auction_id)

    {new_product_state, events} = AuctionBidCalculator.process(product_state, bid, status)
    new_state = AuctionState.update_product_bids(current_state, vessel_fuel_id, new_product_state)

    # TODO: Not this
    auction = Auctions.get_auction!(auction_id) |> Auctions.fully_loaded()
    new_state = SolutionCalculator.process(new_state, auction)
    {new_product_state, events, new_state}
  end

  def revoke_supplier_bids(
         current_state = %{auction_id: auction_id},
         product_id,
         supplier_id
       ) do
    product_state =
      AuctionState.get_state_for_product(current_state, product_id) ||
        ProductBidState.for_product(product_id, auction_id)

    new_product_state = AuctionBidCalculator.revoke_supplier_bids(product_state, supplier_id)
    new_state = AuctionState.update_product_bids(current_state, product_id, new_product_state)

    # TODO: Not this
    auction = Auctions.get_auction!(auction_id) |> Auctions.fully_loaded()
    new_state = SolutionCalculator.process(new_state, auction)
    new_state
  end

  def select_winning_solution(solution = %Solution{}, port_agent, auction, current_state = %{auction_id: auction_id}) do
    auction = %{auction | port_agent: port_agent}
    auction
    |> Command.update_cache()
    |> AuctionCache.process_command()

    AuctionTimer.cancel_timer(auction_id, :decision_duration)

    current_state
    |> Map.put(:winning_solution, solution)
    |> Map.put(:status, :closed)
  end

  def submit_barge(
         auction_barge = %AuctionBarge{
           auction_id: auction_id,
           barge_id: barge_id,
           supplier_id: supplier_id
         },
         current_state = %AuctionState{submitted_barges: submitted_barges}
       ) do
    barge_is_submitted =
      Enum.any?(submitted_barges, fn barge ->
        match?(
          %AuctionBarge{auction_id: ^auction_id, barge_id: ^barge_id, supplier_id: ^supplier_id},
          barge
        )
      end)

    if barge_is_submitted do
      current_state
    else
      %AuctionState{current_state | submitted_barges: submitted_barges ++ [auction_barge]}
    end
  end

  def unsubmit_barge(
         %AuctionBarge{
           auction_id: auction_id,
           barge_id: barge_id,
           supplier_id: supplier_id
         },
         current_state = %AuctionState{submitted_barges: submitted_barges}
       ) do
    new_submitted_barges =
      Enum.reject(submitted_barges, fn barge ->
        match?(
          %AuctionBarge{auction_id: ^auction_id, barge_id: ^barge_id, supplier_id: ^supplier_id},
          barge
        )
      end)

    %AuctionState{current_state | submitted_barges: new_submitted_barges}
  end

  def approve_barge(
         auction_barge = %AuctionBarge{
           auction_id: auction_id,
           barge_id: barge_id,
           supplier_id: supplier_id,
           approval_status: "APPROVED"
         },
         current_state = %AuctionState{submitted_barges: submitted_barges}
       ) do
    new_submitted_barges =
      Enum.map(submitted_barges, fn barge ->
        case barge do
          %AuctionBarge{auction_id: ^auction_id, barge_id: ^barge_id, supplier_id: ^supplier_id} ->
            auction_barge

          _ ->
            barge
        end
      end)

    %AuctionState{current_state | submitted_barges: new_submitted_barges}
  end

  def reject_barge(
         auction_barge = %AuctionBarge{
           auction_id: auction_id,
           barge_id: barge_id,
           supplier_id: supplier_id,
           approval_status: "REJECTED"
         },
         current_state = %AuctionState{submitted_barges: submitted_barges}
       ) do
    new_submitted_barges =
      Enum.map(submitted_barges, fn barge ->
        case barge do
          %AuctionBarge{auction_id: ^auction_id, barge_id: ^barge_id, supplier_id: ^supplier_id} ->
            auction_barge

          _ ->
            barge
        end
      end)

    %AuctionState{current_state | submitted_barges: new_submitted_barges}
  end

  def cancel_auction(auction, current_state = %{auction_id: auction_id}) do
    auction = %{ auction | auction_closed_time: DateTime.utc_now()}

    auction
    |> Command.update_cache()
    |> AuctionCache.process_command()

    AuctionTimer.cancel_timer(auction_id, :duration)
    AuctionTimer.cancel_timer(auction_id, :decision_duration)
    %AuctionState{current_state | status: :canceled}
  end

  def expire_auction(auction, current_state = %{auction_id: auction_id}) do
    auction = %{ auction | auction_closed_time: DateTime.utc_now()}

    auction
    |> Command.update_cache()
    |> AuctionCache.process_command()

    AuctionTimer.cancel_timer(auction_id, :decision_duration)
    %AuctionState{current_state | status: :expired}
  end
end
