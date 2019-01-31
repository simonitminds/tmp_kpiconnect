defimpl Oceanconnect.Auctions.StoreProtocol,
  for: Oceanconnect.Auctions.AuctionStore.TermAuctionState do
  alias Oceanconnect.Auctions

  alias Oceanconnect.Auctions.{
    TermAuction,
    AuctionBarge,
    AuctionBid,
    AuctionBidCalculator,
    AuctionCache,
    AuctionEvent,
    AuctionScheduler,
    AuctionTimer,
    Command,
    ProductBidState,
    SolutionCalculator,
    Solution,
    AuctionStore.TermAuctionState
  }

  def is_suppliers_first_bid?(%TermAuctionState{product_bids: product_bids}, %AuctionBid{
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
        state = %TermAuctionState{},
        bid = %AuctionBid{vessel_fuel_id: vessel_fuel_id}
      ) do
    product_bids = TermAuctionState.get_state_for_product(state, vessel_fuel_id)

    length(product_bids.lowest_bids) == 0 ||
      hd(product_bids.lowest_bids).supplier_id == bid.supplier_id
  end

  def start_auction(
        %TermAuctionState{status: status} = current_state,
        auction = %TermAuction{},
        user,
        emit
      )
      when status in [:pending, :open] do
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
      %TermAuctionState{current_state | status: :open}
      |> AuctionBidCalculator.process_all(:open)

    next_state = SolutionCalculator.process(next_state, auction)

    AuctionEvent.emit(AuctionEvent.auction_started(auction, next_state, user), emit)
    next_state
  end

  def start_auction(
        %TermAuctionState{status: :decision} = current_state,
        auction = %TermAuction{},
        _user,
        _emit
      ) do
    auction
    |> Command.start_decision_duration_timer()
    |> AuctionTimer.process_command()

    auction
    |> Command.cancel_scheduled_start()
    |> AuctionScheduler.process_command(nil)

    current_state
  end

  def start_auction(%TermAuctionState{} = current_state, _auction = %TermAuction{}, _user, _emit) do
    current_state
  end

  def update_auction(
        current_state = %TermAuctionState{status: :draft},
        auction = %TermAuction{scheduled_start: start},
        emit
      )
      when start != nil do
    update_auction_side_effects(auction, emit)

    current_state
    |> Map.put(:status, :pending)
    |> update_product_bid_state(auction)
  end

  def update_auction(current_state = %TermAuctionState{}, auction = %TermAuction{}, emit) do
    update_auction_side_effects(auction, emit)

    current_state
    |> update_product_bid_state(auction)
  end

  defp update_auction_side_effects(auction = %TermAuction{}, emit) do
    auction
    |> Command.update_cache()
    |> AuctionCache.process_command()

    auction
    |> Command.update_scheduled_start()
    |> AuctionScheduler.process_command(emit)
  end

  def update_product_bid_state(
        state = %TermAuctionState{product_bids: product_bids},
        _auction = %TermAuction{id: auction_id, fuel_id: fuel_id}
      ) do
    updated_product_bids = %{
      "#{fuel_id}" =>
        product_bids["#{fuel_id}"] || ProductBidState.for_product(fuel_id, auction_id)
    }

    Map.put(state, :product_bids, updated_product_bids)
  end

  def end_auction(current_state = %TermAuctionState{}, auction = %TermAuction{}) do
    auction
    |> Command.update_cache()
    |> AuctionCache.process_command()

    auction
    |> Command.start_decision_duration_timer()
    |> AuctionTimer.process_command()

    %TermAuctionState{current_state | status: :decision}
  end

  def process_bid(
        current_state = %TermAuctionState{auction_id: auction_id, status: status},
        bid = %{vessel_fuel_id: vessel_fuel_id}
      ) do
    product_state =
      TermAuctionState.get_state_for_product(current_state, vessel_fuel_id) ||
        ProductBidState.for_product(vessel_fuel_id, auction_id)

    {new_product_state, events} = AuctionBidCalculator.process(product_state, bid, status)

    new_state =
      TermAuctionState.update_product_bids(current_state, vessel_fuel_id, new_product_state)

    # TODO: Not this
    auction = Auctions.get_auction!(auction_id) |> Auctions.fully_loaded()
    new_state = SolutionCalculator.process(new_state, auction)
    {new_product_state, events, new_state}
  end

  def revoke_supplier_bids(
        current_state = %TermAuctionState{auction_id: auction_id},
        product_id,
        supplier_id
      ) do
    product_state =
      TermAuctionState.get_state_for_product(current_state, product_id) ||
        ProductBidState.for_product(product_id, auction_id)

    new_product_state = AuctionBidCalculator.revoke_supplier_bids(product_state, supplier_id)
    new_state = TermAuctionState.update_product_bids(current_state, product_id, new_product_state)

    # TODO: Not this
    auction = Auctions.get_auction!(auction_id) |> Auctions.fully_loaded()
    new_state = SolutionCalculator.process(new_state, auction)
    new_state
  end

  def select_winning_solution(
        current_state = %TermAuctionState{auction_id: auction_id},
        solution = %Solution{}
      ) do
    AuctionTimer.cancel_timer(auction_id, :decision_duration)

    current_state
    |> Map.put(:winning_solution, solution)
    |> Map.put(:status, :closed)
  end

  def submit_barge(
        current_state = %TermAuctionState{submitted_barges: submitted_barges},
        auction_barge = %AuctionBarge{
          auction_id: auction_id,
          barge_id: barge_id,
          supplier_id: supplier_id
        }
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
      %TermAuctionState{current_state | submitted_barges: submitted_barges ++ [auction_barge]}
    end
  end

  def unsubmit_barge(
        current_state = %TermAuctionState{submitted_barges: submitted_barges},
        %AuctionBarge{
          auction_id: auction_id,
          barge_id: barge_id,
          supplier_id: supplier_id
        }
      ) do
    new_submitted_barges =
      Enum.reject(submitted_barges, fn barge ->
        match?(
          %AuctionBarge{auction_id: ^auction_id, barge_id: ^barge_id, supplier_id: ^supplier_id},
          barge
        )
      end)

    %TermAuctionState{current_state | submitted_barges: new_submitted_barges}
  end

  def approve_barge(
        current_state = %TermAuctionState{submitted_barges: submitted_barges},
        auction_barge = %AuctionBarge{
          auction_id: auction_id,
          barge_id: barge_id,
          supplier_id: supplier_id,
          approval_status: "APPROVED"
        }
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

    %TermAuctionState{current_state | submitted_barges: new_submitted_barges}
  end

  def reject_barge(
        current_state = %TermAuctionState{submitted_barges: submitted_barges},
        auction_barge = %AuctionBarge{
          auction_id: auction_id,
          barge_id: barge_id,
          supplier_id: supplier_id,
          approval_status: "REJECTED"
        }
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

    %TermAuctionState{current_state | submitted_barges: new_submitted_barges}
  end

  def cancel_auction(current_state = %TermAuctionState{auction_id: auction_id}) do
    AuctionTimer.cancel_timer(auction_id, :duration)
    AuctionTimer.cancel_timer(auction_id, :decision_duration)
    %TermAuctionState{current_state | status: :canceled}
  end

  def expire_auction(current_state = %TermAuctionState{auction_id: auction_id}) do
    AuctionTimer.cancel_timer(auction_id, :decision_duration)
    %TermAuctionState{current_state | status: :expired}
  end
end
