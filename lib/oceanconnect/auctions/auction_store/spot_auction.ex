defimpl Oceanconnect.Auctions.Aggregate, for: Oceanconnect.Auctions.AuctionStore.AuctionState do
  alias Oceanconnect.Auctions

  alias Oceanconnect.Auctions.{
    Auction,
    AuctionBarge,
    AuctionBid,
    AuctionBidCalculator,
    AuctionComment,
    AuctionEvent,
    AuctionEventStore,
    AuctionTimer,
    Command,
    SolutionCalculator,
    Solution,
    AuctionStore.AuctionState,
    AuctionStore.ProductBidState
  }

  defp is_suppliers_first_bid?(%AuctionState{product_bids: product_bids}, %AuctionBid{
         supplier_id: supplier_id
       }) do
    !Enum.any?(
      product_bids,
      fn {_product_key, %ProductBidState{bids: bids}} ->
        Enum.any?(bids, fn bid -> bid.supplier_id == supplier_id end)
      end
    )
  end

  defp is_lowest_bid?(
         product_bids = %ProductBidState{},
         bid = %AuctionBid{}
       ) do
    length(product_bids.lowest_bids) == 0 ||
      hd(product_bids.lowest_bids).supplier_id == bid.supplier_id
  end

  ###
  # Commands
  ###

  def process(
        %AuctionState{},
        %Command{command: :create_auction, data: %{auction: auction, user: user}}
      ) do
    {:ok, [AuctionEvent.auction_created(auction, user)]}
  end

  def process(
        state = %AuctionState{status: status},
        %Command{
          command: :start_auction,
          data: %{auction: auction, user: user, started_at: started_at}
        }
      )
      when status in [:pending] do
    {new_state, events} =
      %AuctionState{state | status: :open}
      |> AuctionBidCalculator.process_all(:open)

    new_state = SolutionCalculator.process(new_state, auction)

    {:ok,
     [
       AuctionEvent.auction_started(auction, new_state, started_at, user)
     ] ++ events}
  end

  def process(
        _state,
        %Command{command: :start_auction}
      ) do
    {:ok, []}
  end

  def process(
        state = %AuctionState{status: :draft},
        %Command{
          command: :update_auction,
          data: %{auction: auction = %{scheduled_start: value}, user: user}
        }
      )
      when not is_nil(value) and value != "" do
    {:ok,
     [
       AuctionEvent.auction_updated(auction, user),
       AuctionEvent.auction_transitioned_from_draft_to_pending(auction, state)
     ]}
  end

  def process(
        _state = %AuctionState{},
        %Command{command: :update_auction, data: %{auction: auction, user: user}}
      ) do
    {:ok,
     [
       AuctionEvent.auction_updated(auction, user)
     ]}
  end

  def process(
        _state = %AuctionState{},
        %Command{command: :reschedule_auction, data: %{auction: auction, user: user}}
      ) do
    {:ok,
     [
       AuctionEvent.auction_rescheduled(auction, user)
     ]}
  end

  def process(
        state = %AuctionState{},
        %Command{
          command: :cancel_auction,
          data: %{auction: auction, canceled_at: canceled_at, user: user}
        }
      ) do
    {:ok,
     [
       AuctionEvent.auction_canceled(auction, canceled_at, state, user),
       AuctionEvent.auction_finalized(auction)
     ]}
  end

  def process(
        state = %AuctionState{status: :open},
        %Command{command: :end_auction, data: %{auction: auction, ended_at: ended_at}}
      ) do
    {:ok,
     [
       AuctionEvent.auction_ended(auction, ended_at, state)
     ]}
  end

  def process(
        _state,
        %Command{command: :end_auction}
      ) do
    {:ok, []}
  end

  def process(
        state = %AuctionState{},
        %Command{
          command: :end_auction_decision_period,
          data: %{auction: auction, expired_at: expired_at}
        }
      ) do
    {:ok,
     [
       AuctionEvent.auction_expired(auction, expired_at, state),
       AuctionEvent.auction_finalized(auction)
     ]}
  end

  def process(
        state = %AuctionState{},
        %Command{
          command: :process_new_bid,
          auction_id: auction_id,
          data: %{
            bid: bid = %{min_amount: nil},
            user: user
          }
        }
      ) do
    {new_product_state, events} = process_bid(state, bid)
    {will_extend, extension_time} = auction_will_extend(state, new_product_state, bid)

    extension_events =
      case will_extend do
        true -> [AuctionEvent.duration_extended(auction_id, extension_time)]
        _ -> []
      end

    {:ok,
     events ++
       [
         AuctionEvent.bid_placed(bid, new_product_state, user)
       ] ++ extension_events}
  end

  def process(
        state = %AuctionState{},
        %Command{
          command: :process_new_bid,
          auction_id: auction_id,
          data: %{
            bid: bid = %{min_amount: _min_amount},
            user: user
          }
        }
      ) do
    {new_product_state, events} = process_bid(state, bid)
    {will_extend, extension_time} = auction_will_extend(state, new_product_state, bid)

    extension_events =
      case will_extend do
        true -> [AuctionEvent.duration_extended(auction_id, extension_time)]
        _ -> []
      end

    {:ok,
     [
       AuctionEvent.auto_bid_placed(bid, new_product_state, user)
     ] ++ events ++ extension_events}
  end

  def process(
        state = %AuctionState{auction_id: auction_id},
        %Command{
          command: :revoke_supplier_bids,
          data: %{product: product, supplier_id: supplier_id, user: user}
        }
      ) do
    {:ok,
     [
       AuctionEvent.bids_revoked(auction_id, product, supplier_id, state, user)
     ]}
  end

  def process(
        state = %AuctionState{},
        %Command{
          command: :select_winning_solution,
          data: %{
            solution: solution = %Solution{},
            auction: auction = %Auction{},
            closed_at: closed_at,
            port_agent: port_agent,
            user: user
          }
        }
      ) do
    {:ok,
     [
       AuctionEvent.winning_solution_selected(
         auction.id,
         solution,
         closed_at,
         port_agent,
         state,
         user
       ),
       AuctionEvent.auction_closed(auction, closed_at, state),
       AuctionEvent.auction_finalized(auction)
     ]}
  end

  def process(
        state = %AuctionState{auction_id: auction_id, submitted_barges: submitted_barges},
        %Command{
          command: :submit_barge,
          data: %{
            auction_barge:
              auction_barge = %AuctionBarge{
                auction_id: auction_id,
                barge_id: barge_id,
                supplier_id: supplier_id
              },
            user: user
          }
        }
      ) do
    barge_is_submitted =
      Enum.any?(submitted_barges, fn barge ->
        match?(
          %AuctionBarge{auction_id: ^auction_id, barge_id: ^barge_id, supplier_id: ^supplier_id},
          barge
        )
      end)

    events =
      if barge_is_submitted,
        do: [],
        else: [AuctionEvent.barge_submitted(auction_barge, state, user)]

    {:ok, events}
  end

  def process(
        state = %AuctionState{auction_id: auction_id, submitted_barges: submitted_barges},
        %Command{
          command: :unsubmit_barge,
          data: %{
            auction_barge:
              auction_barge = %AuctionBarge{
                auction_id: auction_id,
                barge_id: barge_id,
                supplier_id: supplier_id
              },
            user: user
          }
        }
      ) do
    barge_is_submitted =
      Enum.any?(submitted_barges, fn barge ->
        match?(
          %AuctionBarge{auction_id: ^auction_id, barge_id: ^barge_id, supplier_id: ^supplier_id},
          barge
        )
      end)

    events =
      if barge_is_submitted,
        do: [AuctionEvent.barge_unsubmitted(auction_barge, state, user)],
        else: []

    {:ok, events}
  end

  def process(
        state = %AuctionState{auction_id: auction_id, submitted_barges: submitted_barges},
        %Command{
          command: :approve_barge,
          data: %{
            auction_barge:
              auction_barge = %AuctionBarge{
                auction_id: auction_id,
                barge_id: barge_id,
                supplier_id: supplier_id
              },
            user: user
          }
        }
      ) do
    barge_is_approved =
      Enum.any?(submitted_barges, fn barge ->
        match?(
          %AuctionBarge{
            auction_id: ^auction_id,
            barge_id: ^barge_id,
            supplier_id: ^supplier_id,
            approval_status: "APPROVED"
          },
          barge
        )
      end)

    events =
      if barge_is_approved,
        do: [],
        else: [AuctionEvent.barge_approved(auction_barge, state, user)]

    {:ok, events}
  end

  def process(
        state = %AuctionState{auction_id: auction_id, submitted_barges: submitted_barges},
        %Command{
          command: :reject_barge,
          data: %{
            auction_barge:
              auction_barge = %AuctionBarge{
                auction_id: auction_id,
                barge_id: barge_id,
                supplier_id: supplier_id
              },
            user: user
          }
        }
      ) do
    barge_is_rejected =
      Enum.any?(submitted_barges, fn barge ->
        match?(
          %AuctionBarge{
            auction_id: ^auction_id,
            barge_id: ^barge_id,
            supplier_id: ^supplier_id,
            approval_status: "REJECTED"
          },
          barge
        )
      end)

    events =
      if barge_is_rejected,
        do: [],
        else: [AuctionEvent.barge_rejected(auction_barge, state, user)]

    {:ok, events}
  end

  def process(
        state = %AuctionState{submitted_comments: submitted_comments},
        %Command{
          command: :submit_comment,
          data: %{comment: comment = %AuctionComment{id: comment_id}, user: user}
        }
      ) do
    comment_already_submitted =
      Enum.any?(submitted_comments, fn comment ->
        match?(%AuctionComment{id: ^comment_id}, comment)
      end)

    events =
      if comment_already_submitted,
        do: [],
        else: [AuctionEvent.comment_submitted(comment, state, user)]

    {:ok, events}
  end

  def process(
        state = %AuctionState{submitted_comments: submitted_comments},
        %Command{
          command: :unsubmit_comment,
          data: %{comment: comment = %AuctionComment{id: comment_id}, user: user}
        }
      ) do
    comment_already_submitted =
      Enum.any?(submitted_comments, fn comment ->
        match?(%AuctionComment{id: ^comment_id}, comment)
      end)

    events =
      if comment_already_submitted,
        do: [AuctionEvent.comment_unsubmitted(comment, state, user)],
        else: []

    {:ok, events}
  end

  # TODO: Move to Notifications context and fire as a reaction to `auction_rescheduled` or similar.
  def process(
        %AuctionState{auction_id: _auction_id},
        %Command{command: :notify_upcoming_auction, data: %{auction: auction}}
      ) do
    {:ok, [AuctionEvent.upcoming_auction_notified(auction)]}
  end

  def process(
        _state = %AuctionState{auction_id: auction_id},
        command = %Command{command: type}
      ) do
    require Logger
    Logger.warn("AuctionStore for Auction #{auction_id} received unhandled command #{type}")
    {:error, command}
  end

  ###
  # Snapshot
  ###

  def snapshot(state = %AuctionState{}, adapter \\ AuctionEventStore) do
    event = AuctionEvent.auction_state_snapshotted(state)

    event
    |> adapter.persist()

    {:ok, event}
  end

  ###
  # Applications
  ###

  def apply(
        _state,
        %AuctionEvent{
          type: :auction_created,
          data: auction = %{__struct_: Oceanconnect.Auctions.Auction}
        }
      ) do
    auction = Auctions.fully_loaded(auction)
    {:ok, AuctionState.from_auction(auction)}
  end

  def apply(
        state = %AuctionState{auction_id: auction_id, status: status, product_bids: product_bids},
        %AuctionEvent{
          type: :auction_updated,
          data: %Auction{
            scheduled_start: scheduled_start,
            auction_vessel_fuels: vessel_fuels
          }
        }
      ) do
    vessel_fuel_ids = Enum.map(vessel_fuels, &"#{&1.id}")

    updated_product_bids =
      vessel_fuel_ids
      |> Enum.reduce(%{}, fn vfid, acc ->
        if vfid in Map.keys(product_bids) do
          Map.put(acc, vfid, product_bids[vfid])
        else
          Map.put(acc, vfid, ProductBidState.for_product(vfid, auction_id))
        end
      end)

    new_status =
      case {status, scheduled_start} do
        {:draft, nil} -> :draft
        {:draft, _} -> :pending
        _ -> status
      end

    new_state =
      state
      |> Map.put(:product_bids, updated_product_bids)
      |> Map.put(:status, new_status)

    {:ok, new_state}
  end

  def apply(
        state,
        %AuctionEvent{type: :auction_rescheduled}
      ) do
    {:ok, state}
  end

  def apply(
        state = %AuctionState{auction_id: auction_id},
        %AuctionEvent{type: :auction_started}
      ) do
    {next_state, _} =
      %AuctionState{state | status: :open}
      |> AuctionBidCalculator.process_all(:open)

    auction = Auctions.get_auction!(auction_id)
    next_state = SolutionCalculator.process(next_state, auction)
    {:ok, next_state}
  end

  def apply(
        state,
        %AuctionEvent{type: :auction_ended}
      ) do
    {:ok, %AuctionState{state | status: :decision}}
  end

  def apply(
        state,
        %AuctionEvent{type: :auction_expired}
      ) do
    {:ok, %AuctionState{state | status: :expired}}
  end

  def apply(
        state,
        %AuctionEvent{type: :auction_closed}
      ) do
    {:ok, %AuctionState{state | status: :closed}}
  end

  def apply(
        state,
        %AuctionEvent{type: :auction_canceled}
      ) do
    {:ok, %AuctionState{state | status: :canceled}}
  end

  def apply(
        state = %AuctionState{auction_id: auction_id},
        %AuctionEvent{
          type: :bid_placed,
          data: %{bid: bid = %AuctionBid{vessel_fuel_id: vessel_fuel_id}}
        }
      ) do
    {new_product_state, _events} = process_bid(state, bid)
    new_state = AuctionState.update_product_bids(state, vessel_fuel_id, new_product_state)

    auction = Auctions.get_auction!(auction_id)
    new_state = SolutionCalculator.process(new_state, auction)
    {:ok, new_state}
  end

  def apply(
        state = %AuctionState{auction_id: auction_id},
        %AuctionEvent{
          type: :auto_bid_placed,
          data: %{bid: bid = %AuctionBid{vessel_fuel_id: vessel_fuel_id}}
        }
      ) do
    {new_product_state, _events} = process_bid(state, bid)
    new_state = AuctionState.update_product_bids(state, vessel_fuel_id, new_product_state)

    # TODO: Not this
    auction = Auctions.get_auction!(auction_id)
    new_state = SolutionCalculator.process(new_state, auction)

    {:ok, new_state}
  end

  def apply(
        state = %AuctionState{},
        %AuctionEvent{type: :auto_bid_triggered}
      ) do
    # auto_bid_triggered is a side-effect of `AuctionBidCalculator.process()`.
    # That function will always calculate the final state after all auto bids
    # have been updated, meaning that an application of the
    # `auto_bid_triggered` event has no effect.
    {:ok, state}
  end

  def apply(
        state = %AuctionState{auction_id: auction_id},
        %AuctionEvent{type: :bids_revoked, data: %{supplier_id: supplier_id, product: product_id}}
      ) do
    product_state =
      AuctionState.get_state_for_product(state, product_id) ||
        ProductBidState.for_product(product_id, auction_id)

    new_product_state = AuctionBidCalculator.revoke_supplier_bids(product_state, supplier_id)
    new_state = AuctionState.update_product_bids(state, product_id, new_product_state)

    auction = Auctions.get_auction!(auction_id)
    new_state = SolutionCalculator.process(new_state, auction)
    {:ok, new_state}
  end

  def apply(
        state = %AuctionState{},
        %AuctionEvent{type: :duration_extended}
      ) do
    # Extending the duration timer is handled by `EventNotifier.react_to`.
    {:ok, state}
  end

  def apply(
        state = %AuctionState{},
        %AuctionEvent{type: :winning_solution_selected, data: %{solution: solution}}
      ) do
    {:ok, %AuctionState{state | winning_solution: solution}}
  end

  def apply(
        state = %AuctionState{submitted_barges: submitted_barges},
        %AuctionEvent{type: :barge_submitted, data: %{auction_barge: auction_barge}}
      ) do
    {:ok, %AuctionState{state | submitted_barges: submitted_barges ++ [auction_barge]}}
  end

  def apply(
        state = %AuctionState{submitted_barges: submitted_barges},
        %AuctionEvent{
          type: :barge_unsubmitted,
          data: %{
            auction_barge: %AuctionBarge{
              auction_id: auction_id,
              barge_id: barge_id,
              supplier_id: supplier_id
            }
          }
        }
      ) do
    new_submitted_barges =
      Enum.reject(submitted_barges, fn barge ->
        match?(
          %AuctionBarge{auction_id: ^auction_id, barge_id: ^barge_id, supplier_id: ^supplier_id},
          barge
        )
      end)

    {:ok, %AuctionState{state | submitted_barges: new_submitted_barges}}
  end

  def apply(
        state = %AuctionState{submitted_barges: submitted_barges},
        %AuctionEvent{
          type: :barge_approved,
          data: %{
            auction_barge:
              auction_barge = %AuctionBarge{
                auction_id: auction_id,
                barge_id: barge_id,
                supplier_id: supplier_id
              }
          }
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

    {:ok, %AuctionState{state | submitted_barges: new_submitted_barges}}
  end

  def apply(
        state = %AuctionState{submitted_barges: submitted_barges},
        %AuctionEvent{
          type: :barge_rejected,
          data: %{
            auction_barge:
              auction_barge = %AuctionBarge{
                auction_id: auction_id,
                barge_id: barge_id,
                supplier_id: supplier_id
              }
          }
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

    {:ok, %AuctionState{state | submitted_barges: new_submitted_barges}}
  end

  def apply(
        state = %AuctionState{submitted_comments: submitted_comments},
        %AuctionEvent{type: :comment_submitted, data: %{comment: comment}}
      ) do
    {:ok, %AuctionState{state | submitted_comments: submitted_comments ++ [comment]}}
  end

  def apply(
        state = %AuctionState{submitted_comments: submitted_comments},
        %AuctionEvent{
          type: :comment_unsubmitted,
          data: %{comment: %AuctionComment{id: comment_id}}
        }
      ) do
    new_submitted_comments =
      Enum.reject(submitted_comments, fn comment ->
        match?(%AuctionComment{id: ^comment_id}, comment)
      end)

    {:ok, %AuctionState{state | submitted_comments: new_submitted_comments}}
  end

  @nop_events [
    :upcoming_auction_notified,
    :auction_state_snapshotted,
    :auction_finalized
  ]

  def apply(
        state = %AuctionState{},
        %AuctionEvent{type: type}
      )
      when type in @nop_events do
    {:ok, state}
  end

  def apply(
        state = %AuctionState{auction_id: auction_id},
        %AuctionEvent{type: type}
      ) do
    require Logger
    Logger.warn("AuctionStore for Auction #{auction_id} received unhandled event: #{type}")
    {:ok, state}
  end

  ###
  # Utilities
  ###

  def process_bid(
        state = %AuctionState{status: status, auction_id: auction_id},
        bid = %AuctionBid{vessel_fuel_id: vessel_fuel_id}
      ) do
    product_state =
      AuctionState.get_state_for_product(state, vessel_fuel_id) ||
        ProductBidState.for_product(vessel_fuel_id, auction_id)

    AuctionBidCalculator.process(product_state, bid, status)
  end

  def auction_will_extend(state = %AuctionState{auction_id: auction_id}, product_state, bid) do
    should_extend = is_lowest_bid?(product_state, bid) or is_suppliers_first_bid?(state, bid)

    case should_extend do
      true -> AuctionTimer.should_extend?(auction_id)
      _ -> {false, 0}
    end
  end
end
